#import <QuartzCore/QuartzCore.h>

#include "status_island_geometry.h"

extern struct event_loop g_event_loop;
extern struct space_manager g_space_manager;

bool g_status_island_enabled = true;
enum status_island_workspace_order g_status_island_workspace_order = STATUS_ISLAND_ORDER_INDEX;
static bool g_status_island_dirty;

#define STATUS_ISLAND_HEIGHT 30.0f
#define STATUS_ISLAND_WING_MIN_WIDTH 80.0f
#define STATUS_ISLAND_WING_DEFAULT_WIDTH 108.0f
#define STATUS_ISLAND_LAYOUT_WING_WIDTH 100.0f
#define STATUS_ISLAND_WING_MAX_CHARS 64
#define STATUS_ISLAND_CORNER_RADIUS 15.0f
#define STATUS_ISLAND_PADDING 14.0f
#define STATUS_ISLAND_SHADOW_MARGIN 28.0f

static CGPathRef status_island_bottom_rounded_path(CGFloat width, CGFloat height, CGFloat radius)
{
    CGMutablePathRef path = CGPathCreateMutable();
    CGFloat r = MIN(radius, height);

    if (width <= 0 || height <= 0 || r <= 0) {
        CGPathAddRect(path, NULL, CGRectMake(0, 0, width, height));
        return path;
    }

    CGPathMoveToPoint(path, NULL, 0, height);
    CGPathAddLineToPoint(path, NULL, width, height);
    CGPathAddLineToPoint(path, NULL, width, r);
    CGPathAddArc(path, NULL, width - r, r, r, 0, 3.0f * M_PI_2, true);
    CGPathAddLineToPoint(path, NULL, r, 0);
    CGPathAddArc(path, NULL, r, r, r, 3.0f * M_PI_2, M_PI, true);
    CGPathCloseSubpath(path);
    return path;
}

@interface status_island_panel : NSPanel
@end

@implementation status_island_panel
- (BOOL)canBecomeKeyWindow
{
    return NO;
}

- (BOOL)canBecomeMainWindow
{
    return NO;
}
@end

@interface status_island_surface : NSView {
    CGFloat _cornerRadius;
    id _island;
    id _clipView;
}
@property(assign) CGFloat cornerRadius;
@property(assign) id island;
@property(assign) id clipView;
@end

@implementation status_island_surface
@synthesize cornerRadius = _cornerRadius;
@synthesize island = _island;
@synthesize clipView = _clipView;

- (void)layout
{
    [super layout];

    self.wantsLayer = YES;
    self.layer.backgroundColor = NSColor.clearColor.CGColor;

    CGPathRef path = status_island_bottom_rounded_path(self.bounds.size.width, self.bounds.size.height, _cornerRadius);

    NSView *clipView = (NSView *)_clipView;
    if (clipView) {
        clipView.frame = self.bounds;
        clipView.wantsLayer = YES;
        clipView.layer.backgroundColor = NSColor.blackColor.CGColor;
        CAShapeLayer *mask = [CAShapeLayer layer];
        mask.path = path;
        clipView.layer.mask = mask;
    }

    CGPathRelease(path);

    [_island performSelector:@selector(layoutWings)];
}
@end

// Decoration-only surface owned by the mouse-transparent shadow panel. It
// reproduces the island's shadow without also owning clicks or pointer events.
@interface status_island_shadow_surface : NSView {
    CGFloat _cornerRadius;
}
@property(assign) CGFloat cornerRadius;
@end

@implementation status_island_shadow_surface
@synthesize cornerRadius = _cornerRadius;

- (instancetype)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    if (self) {
        self.wantsLayer = YES;
        self.layer.backgroundColor = NSColor.clearColor.CGColor;
    }
    return self;
}

- (void)layout
{
    [super layout];

    self.wantsLayer = YES;
    self.layer.backgroundColor = NSColor.clearColor.CGColor;

    CGPathRef path = status_island_bottom_rounded_path(self.bounds.size.width, self.bounds.size.height, _cornerRadius);
    self.layer.shadowPath = path;
    self.layer.shadowColor = NSColor.blackColor.CGColor;
    self.layer.shadowOpacity = 0.8f;
    self.layer.shadowRadius = 18.0f;
    self.layer.shadowOffset = CGSizeMake(0.0f, -7.0f);
    CGPathRelease(path);
}
@end

@interface status_island_wing : NSView {
    NSImageView *_icon;
    NSView *_label_clip;
    NSTextField *_label;
    NSTextField *_sub;
    SEL _action;
    id _target;
    bool _mirrored;
    bool _marquee_active;
    bool _hovered;
}
@property(assign) SEL action;
@property(assign) id target;
@property(assign) bool mirrored;
@property(readonly) NSTextField *label;
@property(readonly) NSTextField *sub;
@property(readonly) NSImageView *icon;
- (void)setSymbolName:(NSString *)symbolName;
- (void)setLabelText:(NSString *)text;
- (void)setSubText:(NSString *)text;
- (void)startMarquee;
- (void)stopMarquee;
@end

@implementation status_island_wing
@synthesize action = _action;
@synthesize target = _target;
@synthesize mirrored = _mirrored;
@synthesize label = _label;
@synthesize sub = _sub;
@synthesize icon = _icon;

- (instancetype)initWithSymbolName:(NSString *)symbolName mirrored:(bool)mirrored
{
    self = [super initWithFrame:NSZeroRect];
    if (self) {
        _mirrored = mirrored;

        _icon = [[NSImageView alloc] initWithFrame:NSZeroRect];
        _icon.imageScaling = NSImageScaleProportionallyDown;
        _icon.contentTintColor = NSColor.controlAccentColor;
        [self addSubview:_icon];

        _label_clip = [[NSView alloc] initWithFrame:NSZeroRect];
        _label_clip.wantsLayer = YES;
        _label_clip.layer.masksToBounds = YES;
        [self addSubview:_label_clip];

        _label = [NSTextField labelWithString:@""];
        _label.font = [NSFont systemFontOfSize:12.0f weight:NSFontWeightSemibold];
        _label.textColor = NSColor.labelColor;
        _label.lineBreakMode = NSLineBreakByTruncatingTail;
        _label.alignment = _mirrored ? NSTextAlignmentRight : NSTextAlignmentLeft;
        [_label_clip addSubview:_label];

        _sub = [NSTextField labelWithString:@""];
        _sub.font = [NSFont systemFontOfSize:8.5f weight:NSFontWeightSemibold];
        _sub.textColor = NSColor.secondaryLabelColor;
        _sub.alignment = _mirrored ? NSTextAlignmentRight : NSTextAlignmentLeft;
        [self addSubview:_sub];

        [self setSymbolName:symbolName];
    }
    return self;
}

- (void)dealloc
{
    [_icon release];
    [_label_clip release];
    [super dealloc];
}

- (void)setSymbolName:(NSString *)symbolName
{
    NSImage *image = [NSImage imageWithSystemSymbolName:symbolName accessibilityDescription:nil];
    image = [image imageWithSymbolConfiguration:[NSImageSymbolConfiguration configurationWithPointSize:13.0f weight:NSFontWeightMedium]];
    _icon.image = image;
}

- (void)setLabelText:(NSString *)text
{
    _label.stringValue = text ?: @"";
}

- (void)setSubText:(NSString *)text
{
    _sub.stringValue = text ?: @"";
}

- (void)layout
{
    [super layout];

    CGFloat w = self.bounds.size.width;
    CGFloat h = self.bounds.size.height;
    CGFloat iconSize = 14.0f;
    CGFloat gap = 7.0f;
    CGFloat padding = STATUS_ISLAND_PADDING;
    CGFloat labelHeight = 13.0f;
    CGFloat subHeight = 9.0f;
    CGFloat vgap = 1.0f;

    CGFloat textTotal = labelHeight + vgap + subHeight;
    CGFloat textTop = h - (h - textTotal) / 2.0f;
    CGFloat iconY = (h - iconSize) / 2.0f;

    if (_mirrored) {
        _icon.frame = NSMakeRect(w - padding - iconSize, iconY, iconSize, iconSize);
        CGFloat textX = padding;
        CGFloat textWidth = w - padding * 2.0f - iconSize - gap;
        _label_clip.frame = NSMakeRect(textX, textTop - labelHeight, textWidth, labelHeight);
        _sub.frame = NSMakeRect(textX, textTop - labelHeight - vgap - subHeight, textWidth, subHeight);
    } else {
        _icon.frame = NSMakeRect(padding, iconY, iconSize, iconSize);
        CGFloat textX = padding + iconSize + gap;
        CGFloat textWidth = w - padding * 2.0f - iconSize - gap;
        _label_clip.frame = NSMakeRect(textX, textTop - labelHeight, textWidth, labelHeight);
        _sub.frame = NSMakeRect(textX, textTop - labelHeight - vgap - subHeight, textWidth, subHeight);
    }

    if (!_marquee_active) {
        _label.frame = _label_clip.bounds;
    }
}

- (void)startMarquee
{
    if (_marquee_active) return;

    NSDictionary *attributes = @{ NSFontAttributeName: _label.font };
    CGFloat textWidth = ceil([_label.stringValue sizeWithAttributes:attributes].width);
    CGFloat clipWidth = _label_clip.bounds.size.width;
    if (textWidth <= clipWidth + 2.0f) return;

    _marquee_active = true;
    _label.lineBreakMode = NSLineBreakByClipping;
    _label.frame = NSMakeRect(0, 0, textWidth, _label_clip.bounds.size.height);

    CGFloat distance = textWidth - clipWidth + 4.0f;
    CGFloat duration = MAX(1.2f, distance * 0.03f);
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = duration;
        context.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
        [[_label animator] setFrameOrigin:NSMakePoint(-distance, 0)];
    } completionHandler:nil];
}

- (void)stopMarquee
{
    if (!_marquee_active) return;
    _marquee_active = false;

    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = 0.25f;
        [[_label animator] setFrameOrigin:NSMakePoint(0, 0)];
    } completionHandler:^{
        _label.lineBreakMode = NSLineBreakByTruncatingTail;
        _label.frame = _label_clip.bounds;
    }];
}

- (void)mouseDown:(NSEvent *)event
{
    if (_action && _target) {
        [NSApp sendAction:_action to:_target from:self];
    }
}

- (void)updateTrackingAreas
{
    [super updateTrackingAreas];
    for (NSTrackingArea *area in self.trackingAreas) {
        [self removeTrackingArea:area];
    }

    NSTrackingArea *area = [[NSTrackingArea alloc] initWithRect:self.bounds
                                                        options:NSTrackingActiveAlways | NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingInVisibleRect
                                                          owner:self
                                                       userInfo:nil];
    [self addTrackingArea:area];
    [area release];
}

- (void)mouseEntered:(NSEvent *)event
{
    _hovered = true;
    [self startMarquee];
    [self setNeedsDisplay:YES];
}

- (void)mouseExited:(NSEvent *)event
{
    _hovered = false;
    [self stopMarquee];
    [self setNeedsDisplay:YES];
}

- (void)mouseMoved:(NSEvent *)event
{
    if (!_hovered) {
        _hovered = true;
        [self setNeedsDisplay:YES];
    }
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];

    if (_hovered) {
        [[NSColor colorWithWhite:1.0f alpha:0.08f] setFill];
        NSRectFill(self.bounds);
    }
}
@end

@interface status_island_menu_row : NSView {
    NSTextField *_title;
    NSTextField *_meta;
    NSImageView *_dot;
    SEL _action;
    id _target;
    void *_context;
    bool _hovered;
}
@property(assign) SEL action;
@property(assign) id target;
@property(assign) void *context;
- (void)setTitle:(NSString *)title meta:(NSString *)meta checked:(bool)checked;
@end

@implementation status_island_menu_row
@synthesize action = _action;
@synthesize target = _target;
@synthesize context = _context;

- (instancetype)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    if (self) {
        _title = [NSTextField labelWithString:@""];
        _title.font = [NSFont systemFontOfSize:12.5f];
        _title.textColor = NSColor.labelColor;
        _title.lineBreakMode = NSLineBreakByTruncatingTail;
        [self addSubview:_title];

        _meta = [NSTextField labelWithString:@""];
        _meta.font = [NSFont systemFontOfSize:10.0f];
        _meta.textColor = NSColor.secondaryLabelColor;
        _meta.alignment = NSTextAlignmentRight;
        [self addSubview:_meta];

        _dot = [[NSImageView alloc] initWithFrame:NSZeroRect];
        _dot.imageScaling = NSImageScaleProportionallyDown;
        [self addSubview:_dot];
    }
    return self;
}

- (void)dealloc
{
    [_dot release];
    [super dealloc];
}

- (void)setTitle:(NSString *)title meta:(NSString *)meta checked:(bool)checked
{
    _title.stringValue = title ?: @"";
    _meta.stringValue = meta ?: @"";
    NSString *symbol = checked ? @"circle.fill" : @"circle";
    _dot.image = [NSImage imageWithSystemSymbolName:symbol accessibilityDescription:nil];
    _dot.contentTintColor = checked ? NSColor.controlAccentColor : NSColor.tertiaryLabelColor;
}

- (void)layout
{
    [super layout];
    CGFloat w = self.bounds.size.width;
    CGFloat h = self.bounds.size.height;
    CGFloat dotSize = 9.0f;
    _dot.frame = NSMakeRect(10, (h - dotSize) / 2.0f, dotSize, dotSize);
    CGFloat titleX = 26.0f;
    CGFloat metaWidth = w * 0.30f;
    _meta.frame = NSMakeRect(w - 10 - metaWidth, (h - 16) / 2.0f, metaWidth, 16);
    _title.frame = NSMakeRect(titleX, (h - 16) / 2.0f, w - titleX - metaWidth - 20.0f, 16);
}

- (void)mouseDown:(NSEvent *)event
{
    if (_action && _target) {
        [NSApp sendAction:_action to:_target from:self];
    }
}

- (void)updateTrackingAreas
{
    [super updateTrackingAreas];
    for (NSTrackingArea *area in self.trackingAreas) {
        [self removeTrackingArea:area];
    }
    NSTrackingArea *area = [[NSTrackingArea alloc] initWithRect:self.bounds
                                                        options:NSTrackingActiveAlways | NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingInVisibleRect
                                                          owner:self
                                                       userInfo:nil];
    [self addTrackingArea:area];
    [area release];
}

- (void)mouseEntered:(NSEvent *)event
{
    _hovered = true;
    [self setNeedsDisplay:YES];
}

- (void)mouseExited:(NSEvent *)event
{
    _hovered = false;
    [self setNeedsDisplay:YES];
}

- (void)mouseMoved:(NSEvent *)event
{
    if (!_hovered) {
        _hovered = true;
        [self setNeedsDisplay:YES];
    }
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    if (_hovered) {
        [[NSColor colorWithWhite:1.0f alpha:0.09f] setFill];
        [[NSBezierPath bezierPathWithRoundedRect:NSInsetRect(self.bounds, 4.0f, 2.0f) xRadius:6.0f yRadius:6.0f] fill];
    }
}
@end

@interface status_island : NSObject {
    uint32_t _did;
    status_island_panel *_panel;
    status_island_panel *_shadow_panel;
    status_island_surface *_surface;
    status_island_wing *_workspace_wing;
    status_island_wing *_layout_wing;
    NSPanel *_workspace_menu;
    NSPanel *_workspace_menu_shadow;
    NSPanel *_layout_menu;
    NSPanel *_layout_menu_shadow;
    id _event_monitor;
    bool _collapsed;
    uint64_t _focused_sid;
    enum view_type _focused_layout;
    CGFloat _notch_width;
    CGFloat _workspace_wing_width;
    CGFloat _notch_height;
    CGFloat _notch_center_x;
    CGFloat _screen_top_y;
    NSScreen *_screen;
    NSMutableArray *_space_items;
}
- (instancetype)initWithDisplayID:(uint32_t)did;
- (void)show;
- (void)hide;
- (void)updateWithSnapshot:(struct space_workflow_snapshot *)snapshot;
- (void)updateCollapsedForMouse:(NSPoint)mouse;
@end

@implementation status_island
- (instancetype)initWithDisplayID:(uint32_t)did
{
    self = [super init];
    if (self) {
        _did = did;
        _space_items = [[NSMutableArray alloc] init];
        _workspace_wing_width = STATUS_ISLAND_WING_DEFAULT_WIDTH;
    }
    return self;
}

- (void)dealloc
{
    if (_event_monitor) [NSEvent removeMonitor:_event_monitor];
    [_workspace_menu close];
    [_workspace_menu release];
    [_workspace_menu_shadow close];
    [_workspace_menu_shadow release];
    [_layout_menu close];
    [_layout_menu release];
    [_layout_menu_shadow close];
    [_layout_menu_shadow release];
    [_panel close];
    [_panel release];
    [_shadow_panel close];
    [_shadow_panel release];
    [_space_items release];
    [super dealloc];
}

- (NSScreen *)screenForDisplay:(uint32_t)did
{
    for (NSScreen *screen in [NSScreen screens]) {
        NSNumber *screen_number = [[screen deviceDescription] objectForKey:@"NSScreenNumber"];
        if (screen_number && [screen_number unsignedIntValue] == did) {
            return screen;
        }
    }
    return nil;
}

- (CGFloat)islandWidth
{
    return _collapsed ? _notch_width : _workspace_wing_width + _notch_width + STATUS_ISLAND_LAYOUT_WING_WIDTH;
}

- (status_island_geometry)geometry
{
    status_island_geometry g;
    g.shadow_margin = STATUS_ISLAND_SHADOW_MARGIN;
    g.island_height = STATUS_ISLAND_HEIGHT;
    g.corner_radius = STATUS_ISLAND_CORNER_RADIUS;
    g.layout_wing_width = STATUS_ISLAND_LAYOUT_WING_WIDTH;
    g.notch_width = _notch_width;
    g.notch_height = _notch_height;
    g.notch_center_x = _notch_center_x;
    g.screen_top_y = _screen_top_y;
    g.workspace_wing_width = _workspace_wing_width;
    g.collapsed = _collapsed;
    return g;
}

// Tight input frame: the visible surface only. Shadow margins are excluded.
- (NSRect)visibleFrame
{
    return NSRectFromCGRect(status_island_visible_frame([self geometry]));
}

// Expanded decoration frame used only by the mouse-transparent shadow panel.
- (NSRect)shadowFrame
{
    return NSRectFromCGRect(status_island_shadow_frame([self geometry]));
}

- (CGFloat)workspaceWingWidthForName:(NSString *)name
{
    NSString *measured = name;
    if (measured.length > STATUS_ISLAND_WING_MAX_CHARS) {
        measured = [measured substringToIndex:STATUS_ISLAND_WING_MAX_CHARS];
    }
    if (!measured.length) measured = @" ";

    NSTextField *probe = [NSTextField labelWithString:measured];
    probe.font = _workspace_wing.label.font;
    CGFloat labelWidth = ceil(probe.intrinsicContentSize.width);
    CGFloat subWidth = ceil(_workspace_wing.sub.intrinsicContentSize.width);
    CGFloat textWidth = MAX(labelWidth, subWidth) + 4.0f;

    CGFloat wingWidth = STATUS_ISLAND_PADDING * 2.0f + 14.0f + 7.0f + textWidth;
    return MAX(wingWidth, STATUS_ISLAND_WING_MIN_WIDTH);
}

- (void)show
{
    NSScreen *screen = [self screenForDisplay:_did];
    if (!screen) return;
    _screen = screen;

    NSRect topLeft = NSZeroRect;
    NSRect topRight = NSZeroRect;
    if (@available(macOS 12.0, *)) {
        topLeft = screen.auxiliaryTopLeftArea;
        topRight = screen.auxiliaryTopRightArea;
    }
    CGFloat notchLeft = NSMaxX(topLeft);
    CGFloat notchRight = NSMinX(topRight);

    if (notchRight > notchLeft) {
        _notch_width = notchRight - notchLeft;
        _notch_center_x = (notchLeft + notchRight) / 2.0f;
    } else {
        _notch_width = 0;
        _notch_center_x = screen.frame.origin.x + screen.frame.size.width / 2.0f;
    }

    CGFloat notchHeight = 0;
    if (@available(macOS 12.0, *)) {
        notchHeight = screen.safeAreaInsets.top;
    }
    _notch_height = MAX(STATUS_ISLAND_HEIGHT, notchHeight);
    _screen_top_y = screen.frame.origin.y + screen.frame.size.height;

    if (!_panel) {
    CGFloat width = [self islandWidth];
    CGFloat height = _notch_height;

    // Tight, mouse-interactive content panel: visible surface only, no shadow.
    _panel = [[status_island_panel alloc] initWithContentRect:[self visibleFrame]
                                                    styleMask:NSWindowStyleMaskBorderless | NSWindowStyleMaskNonactivatingPanel
                                                      backing:NSBackingStoreBuffered
                                                        defer:NO];
    _panel.opaque = NO;
    _panel.backgroundColor = NSColor.clearColor;
    _panel.hasShadow = NO;
    _panel.hidesOnDeactivate = NO;
    _panel.releasedWhenClosed = NO;
    _panel.ignoresMouseEvents = NO;
    _panel.animationBehavior = NSWindowAnimationBehaviorNone;
    _panel.level = NSStatusWindowLevel;
    _panel.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces | NSWindowCollectionBehaviorTransient | NSWindowCollectionBehaviorFullScreenAuxiliary;
    _panel.acceptsMouseMovedEvents = YES;

    NSView *container = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, width, height)];
    container.wantsLayer = YES;
    _panel.contentView = container;
    [container release];

    _surface = [[status_island_surface alloc] initWithFrame:NSMakeRect(0, 0, width, height)];
    _surface.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    _surface.cornerRadius = STATUS_ISLAND_CORNER_RADIUS;
    _surface.island = self;
    [container addSubview:_surface];

    NSView *clipView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, width, height)];
    clipView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    [_surface addSubview:clipView];
    _surface.clipView = clipView;
    [clipView release];

    _workspace_wing = [[status_island_wing alloc] initWithSymbolName:@"rectangle.3.group" mirrored:false];
    _workspace_wing.action = @selector(workspaceWingClicked:);
    _workspace_wing.target = self;
    [_workspace_wing setSubText:@"WORKSPACE"];
    [clipView addSubview:_workspace_wing];

    _layout_wing = [[status_island_wing alloc] initWithSymbolName:@"rectangle.stack" mirrored:true];
    _layout_wing.action = @selector(layoutWingClicked:);
    _layout_wing.target = self;
    [_layout_wing setSubText:@"LAYOUT"];
    [clipView addSubview:_layout_wing];

    // Mouse-transparent decoration panel owns the shadow and never input.
    NSRect shadowRect = [self shadowFrame];
    _shadow_panel = [[status_island_panel alloc] initWithContentRect:shadowRect
                                                           styleMask:NSWindowStyleMaskBorderless | NSWindowStyleMaskNonactivatingPanel
                                                             backing:NSBackingStoreBuffered
                                                               defer:NO];
    _shadow_panel.opaque = NO;
    _shadow_panel.backgroundColor = NSColor.clearColor;
    _shadow_panel.hasShadow = NO;
    _shadow_panel.hidesOnDeactivate = NO;
    _shadow_panel.releasedWhenClosed = NO;
    _shadow_panel.ignoresMouseEvents = YES;
    _shadow_panel.animationBehavior = NSWindowAnimationBehaviorNone;
    _shadow_panel.level = NSStatusWindowLevel;
    _shadow_panel.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces | NSWindowCollectionBehaviorTransient | NSWindowCollectionBehaviorFullScreenAuxiliary;

    NSView *shadowContainer = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, shadowRect.size.width, shadowRect.size.height)];
    shadowContainer.wantsLayer = YES;
    _shadow_panel.contentView = shadowContainer;
    [shadowContainer release];

    status_island_shadow_surface *shadowSurface = [[status_island_shadow_surface alloc] initWithFrame:NSMakeRect(STATUS_ISLAND_SHADOW_MARGIN, STATUS_ISLAND_SHADOW_MARGIN, width, height)];
    shadowSurface.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    shadowSurface.cornerRadius = STATUS_ISLAND_CORNER_RADIUS;
    [shadowContainer addSubview:shadowSurface];
    // Ensure the rounded shadowPath is present on first show; later resizes
    // are handled by the autoresizing mask triggering layout.
    [shadowSurface setNeedsLayout:YES];
    [shadowSurface layoutSubtreeIfNeeded];
    [shadowSurface release];

    [_surface release];
    [_workspace_wing release];
    [_layout_wing release];
    }

    [self applyFrameAnimated:NO];
    [self layoutWings];
    [_shadow_panel orderFrontRegardless];
    [_panel orderFrontRegardless];
}

- (void)hide
{
    [_panel orderOut:nil];
    [_shadow_panel orderOut:nil];
}

- (void)layoutWings
{
    CGFloat width = _surface.bounds.size.width;
    CGFloat height = _surface.bounds.size.height;

    _workspace_wing.frame = NSMakeRect(0, 0, _workspace_wing_width, height);
    _layout_wing.frame = NSMakeRect(width - STATUS_ISLAND_LAYOUT_WING_WIDTH, 0, STATUS_ISLAND_LAYOUT_WING_WIDTH, height);
}

- (void)applyFrameAnimated:(bool)animated
{
    if (!_panel) return;

    NSRect inputFrame = [self visibleFrame];
    NSRect shadowRect = [self shadowFrame];

    if (animated) {
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
            context.duration = 0.2f;
            context.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
            [[_panel animator] setFrame:inputFrame display:YES];
            [[_shadow_panel animator] setFrame:shadowRect display:YES];
        } completionHandler:nil];
    } else {
        [_panel setFrame:inputFrame display:YES];
        [_shadow_panel setFrame:shadowRect display:YES];
    }
}

- (void)applyStretchFrameAnimated
{
    if (!_panel) return;

    NSRect inputFrame = [self visibleFrame];
    NSRect shadowRect = [self shadowFrame];

    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = 0.32f;
        context.timingFunction = [CAMediaTimingFunction functionWithControlPoints:0.34f :1.56f :0.64f :1.0f];
        [[_panel animator] setFrame:inputFrame display:YES];
        [[_shadow_panel animator] setFrame:shadowRect display:YES];
    } completionHandler:nil];
}

- (void)setCollapsed:(bool)collapsed
{
    if (_collapsed == collapsed || !_panel) return;
    _collapsed = collapsed;

    if (collapsed) {
        [self dismissMenus];
        [_workspace_wing stopMarquee];
    }

    _workspace_wing.hidden = collapsed;
    _layout_wing.hidden = collapsed;

    [self applyFrameAnimated:YES];
}

- (void)dismissMenus
{
    if (_workspace_menu) [_workspace_menu orderOut:nil];
    if (_workspace_menu_shadow) [_workspace_menu_shadow orderOut:nil];
    if (_layout_menu) [_layout_menu orderOut:nil];
    if (_layout_menu_shadow) [_layout_menu_shadow orderOut:nil];
    if (_event_monitor) {
        [NSEvent removeMonitor:_event_monitor];
        _event_monitor = nil;
    }
}

- (void)invalidateMenus
{
    if (_workspace_menu) {
        [_workspace_menu close];
        [_workspace_menu release];
        _workspace_menu = nil;
    }
    if (_workspace_menu_shadow) {
        [_workspace_menu_shadow close];
        [_workspace_menu_shadow release];
        _workspace_menu_shadow = nil;
    }
    if (_layout_menu) {
        [_layout_menu close];
        [_layout_menu release];
        _layout_menu = nil;
    }
    if (_layout_menu_shadow) {
        [_layout_menu_shadow close];
        [_layout_menu_shadow release];
        _layout_menu_shadow = nil;
    }
}

- (void)addOutsideClickMonitor
{
    if (_event_monitor) return;
    _event_monitor = [NSEvent addGlobalMonitorForEventsMatchingMask:NSEventMaskLeftMouseDown | NSEventMaskRightMouseDown
                                                           handler:^(NSEvent *__unused event) {
        NSPoint location = [NSEvent mouseLocation];
        bool inMenu = (_workspace_menu && _workspace_menu.visible && NSPointInRect(location, _workspace_menu.frame)) ||
                      (_layout_menu && _layout_menu.visible && NSPointInRect(location, _layout_menu.frame));
        if (!inMenu) {
            [self dismissMenus];
        }
    }];
}

- (NSPanel *)makeMenuInputPanelWithWidth:(CGFloat)width height:(CGFloat)height
{
    NSPanel *panel = [[NSPanel alloc] initWithContentRect:NSMakeRect(0, 0, width, height)
                                                styleMask:NSWindowStyleMaskBorderless | NSWindowStyleMaskNonactivatingPanel
                                                  backing:NSBackingStoreBuffered
                                                    defer:NO];
    panel.opaque = NO;
    panel.backgroundColor = NSColor.clearColor;
    panel.hasShadow = NO;
    panel.hidesOnDeactivate = NO;
    panel.releasedWhenClosed = NO;
    panel.ignoresMouseEvents = NO;
    panel.animationBehavior = NSWindowAnimationBehaviorNone;
    panel.level = NSStatusWindowLevel;
    panel.acceptsMouseMovedEvents = YES;
    panel.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces | NSWindowCollectionBehaviorTransient | NSWindowCollectionBehaviorFullScreenAuxiliary;

    NSView *content = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, width, height)];
    content.wantsLayer = YES;
    content.layer.backgroundColor = [NSColor colorWithWhite:0.07f alpha:0.98f].CGColor;
    content.layer.cornerRadius = 13.0f;
    content.layer.masksToBounds = YES;
    panel.contentView = content;
    [content release];

    return panel;
}

- (NSPanel *)makeMenuShadowPanelWithWidth:(CGFloat)width height:(CGFloat)height
{
    CGFloat margin = STATUS_ISLAND_SHADOW_MARGIN;

    NSPanel *panel = [[NSPanel alloc] initWithContentRect:NSMakeRect(0, 0, width + 2.0f * margin, height + margin)
                                                styleMask:NSWindowStyleMaskBorderless | NSWindowStyleMaskNonactivatingPanel
                                                  backing:NSBackingStoreBuffered
                                                    defer:NO];
    panel.opaque = NO;
    panel.backgroundColor = NSColor.clearColor;
    panel.hasShadow = NO;
    panel.hidesOnDeactivate = NO;
    panel.releasedWhenClosed = NO;
    panel.ignoresMouseEvents = YES;
    panel.animationBehavior = NSWindowAnimationBehaviorNone;
    panel.level = NSStatusWindowLevel;
    panel.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces | NSWindowCollectionBehaviorTransient | NSWindowCollectionBehaviorFullScreenAuxiliary;

    NSView *container = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, width + 2.0f * margin, height + margin)];
    container.wantsLayer = YES;
    container.layer.backgroundColor = NSColor.clearColor.CGColor;

    CGPathRef shadowPath = CGPathCreateWithRoundedRect(CGRectMake(margin, margin, width, height), 13.0f, 13.0f, NULL);
    container.layer.shadowPath = shadowPath;
    container.layer.shadowColor = NSColor.blackColor.CGColor;
    container.layer.shadowOpacity = 0.7f;
    container.layer.shadowRadius = 14.0f;
    container.layer.shadowOffset = CGSizeMake(0.0f, -5.0f);
    CGPathRelease(shadowPath);

    panel.contentView = container;
    [container release];

    return panel;
}

- (void)buildWorkspaceMenu
{
    if (_workspace_menu) return;

    NSUInteger count = _space_items.count;
    NSUInteger visibleRows = MIN(count, (NSUInteger)10);
    CGFloat rowHeight = 30.0f;
    CGFloat listWidth = 218.0f;

    CGFloat menuWidth = 230.0f;
    CGFloat menuHeight = visibleRows * rowHeight + 12.0f;
    _workspace_menu = [self makeMenuInputPanelWithWidth:menuWidth height:menuHeight];
    _workspace_menu_shadow = [self makeMenuShadowPanelWithWidth:menuWidth height:menuHeight];
    NSView *content = _workspace_menu.contentView;

    NSView *listView = nil;
    if (count > visibleRows) {
        NSScrollView *scroll = [[NSScrollView alloc] initWithFrame:NSMakeRect(6.0f, 6.0f, listWidth, visibleRows * rowHeight)];
        scroll.drawsBackground = NO;
        scroll.hasVerticalScroller = YES;
        scroll.autohidesScrollers = YES;
        scroll.scrollerStyle = NSScrollerStyleOverlay;
        scroll.borderType = NSNoBorder;
        NSView *document = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, listWidth, count * rowHeight)];
        scroll.documentView = document;
        [content addSubview:scroll];
        listView = document;
        [scroll release];
    } else {
        listView = [[NSView alloc] initWithFrame:NSMakeRect(6.0f, 6.0f, listWidth, count * rowHeight)];
        [content addSubview:listView];
    }

    for (NSUInteger i = 0; i < count; ++i) {
        native_palette_item *item = _space_items[i];
        status_island_menu_row *row = [[status_island_menu_row alloc] initWithFrame:NSZeroRect];
        row.action = @selector(workspaceRowClicked:);
        row.target = self;
        row.context = (void *)(uintptr_t)item.representedValue;
        [row setTitle:item.title meta:item.detail checked:(item.representedValue == _focused_sid)];
        row.frame = NSMakeRect(0, i * rowHeight, listWidth, rowHeight);
        [listView addSubview:row];
        [row release];
    }
    [listView release];
}

- (void)buildLayoutMenu
{
    if (_layout_menu) return;

    CGFloat menuWidth = 150.0f;
    CGFloat menuHeight = 3 * 30.0f + 12.0f;
    _layout_menu = [self makeMenuInputPanelWithWidth:menuWidth height:menuHeight];
    _layout_menu_shadow = [self makeMenuShadowPanelWithWidth:menuWidth height:menuHeight];
    NSView *content = _layout_menu.contentView;
    CGFloat rowHeight = 30.0f;
    enum view_type layouts[] = { VIEW_BSP, VIEW_STACK, VIEW_FLOAT };
    for (int i = 0; i < 3; ++i) {
        status_island_menu_row *row = [[status_island_menu_row alloc] initWithFrame:NSZeroRect];
        row.action = @selector(layoutRowClicked:);
        row.target = self;
        row.context = (void *)(uintptr_t)layouts[i];
        [row setTitle:[self layoutName:layouts[i]] meta:@"" checked:(layouts[i] == _focused_layout)];
        row.frame = NSMakeRect(6.0f, 6.0f + i * rowHeight, 138.0f, rowHeight);
        [content addSubview:row];
        [row release];
    }
}

- (void)showWorkspaceMenu
{
    if (_workspace_menu && _workspace_menu.visible) {
        [self dismissMenus];
        return;
    }
    [self dismissMenus];
    [self buildWorkspaceMenu];

    NSRect islandFrame = [self visibleFrame];
    NSRect menuFrame = _workspace_menu.frame;
    menuFrame.origin.x = islandFrame.origin.x;
    menuFrame.origin.y = islandFrame.origin.y - menuFrame.size.height - 6.0f;
    [_workspace_menu setFrame:menuFrame display:NO];
    [_workspace_menu_shadow setFrameOrigin:NSMakePoint(menuFrame.origin.x - STATUS_ISLAND_SHADOW_MARGIN,
                                                        menuFrame.origin.y - STATUS_ISLAND_SHADOW_MARGIN)];
    [_workspace_menu_shadow orderFrontRegardless];
    [_workspace_menu orderFrontRegardless];
    [self addOutsideClickMonitor];
}

- (void)showLayoutMenu
{
    if (_layout_menu && _layout_menu.visible) {
        [self dismissMenus];
        return;
    }
    [self dismissMenus];
    [self buildLayoutMenu];

    NSRect islandFrame = [self visibleFrame];
    NSRect menuFrame = _layout_menu.frame;
    menuFrame.origin.x = islandFrame.origin.x + islandFrame.size.width - menuFrame.size.width;
    menuFrame.origin.y = islandFrame.origin.y - menuFrame.size.height - 6.0f;
    [_layout_menu setFrame:menuFrame display:NO];
    [_layout_menu_shadow setFrameOrigin:NSMakePoint(menuFrame.origin.x - STATUS_ISLAND_SHADOW_MARGIN,
                                                     menuFrame.origin.y - STATUS_ISLAND_SHADOW_MARGIN)];
    [_layout_menu_shadow orderFrontRegardless];
    [_layout_menu orderFrontRegardless];
    [self addOutsideClickMonitor];
}

- (void)workspaceWingClicked:(id)sender
{
    [self showWorkspaceMenu];
}

- (void)layoutWingClicked:(id)sender
{
    [self showLayoutMenu];
}

- (void)workspaceRowClicked:(id)sender
{
    status_island_menu_row *row = sender;
    uint64_t sid = (uint64_t)(uintptr_t)row.context;
    [self dismissMenus];
    if (sid) space_workflow_submit(COMMAND_PALETTE_NATIVE_SPACE_CHOOSE, sid, NULL);
}

- (void)layoutRowClicked:(id)sender
{
    status_island_menu_row *row = sender;
    enum view_type layout = (enum view_type)(uintptr_t)row.context;
    [self dismissMenus];
    space_workflow_submit_layout(layout);
}

- (NSString *)layoutSymbolName:(enum view_type)layout
{
    return layout == VIEW_STACK ? @"rectangle.stack"
         : layout == VIEW_BSP ? @"rectangle.split.2x1"
         : @"rectangle.inset.filled";
}

- (NSString *)layoutName:(enum view_type)layout
{
    return layout == VIEW_STACK ? @"Stack"
         : layout == VIEW_BSP ? @"BSP"
         : @"Float";
}

- (native_palette_item *)spaceItemForSpace:(struct space_workflow_space *)space
{
    NSString *name = space->label && *space->label
                   ? [NSString stringWithUTF8String:space->label]
                   : [NSString stringWithFormat:@"Space %d", space->index];
    NSString *meta = [NSString stringWithFormat:@"%d window%@", space->window_count, space->window_count == 1 ? @"" : @"s"];
    native_palette_item *item = [native_palette_item itemWithTitle:name
                                                            detail:meta
                                                          category:@""
                                                        symbolName:@"rectangle.3.group"
                                                              kind:NATIVE_PALETTE_ITEM_SPACE];
    item.representedValue = space->sid;
    return item;
}

- (void)updateWithSnapshot:(struct space_workflow_snapshot *)snapshot
{
    bool existed = (_panel != nil);
    CGFloat oldWingWidth = _workspace_wing_width;

    [self show];
    if (!_panel) return;

    uint64_t current_sid = 0;
    enum view_type current_layout = VIEW_FLOAT;
    int current_index = 0;

    [_space_items removeAllObjects];

    for (int i = 0; i < snapshot->count; ++i) {
        if (snapshot->spaces[i].display_id != _did) continue;
        if (snapshot->spaces[i].display_current) {
            current_sid = snapshot->spaces[i].sid;
            current_layout = snapshot->spaces[i].layout;
            current_index = snapshot->spaces[i].index;
        }
    }

    for (int i = 0; i < snapshot->count; ++i) {
        if (snapshot->spaces[i].display_id == _did && snapshot->spaces[i].sid == current_sid) {
            [_space_items addObject:[self spaceItemForSpace:&snapshot->spaces[i]]];
            break;
        }
    }

    NSMutableArray *remaining = [NSMutableArray array];
    for (int i = 0; i < snapshot->count; ++i) {
        if (snapshot->spaces[i].display_id == _did && snapshot->spaces[i].sid != current_sid) {
            [remaining addObject:[NSValue valueWithPointer:&snapshot->spaces[i]]];
        }
    }

    [remaining sortUsingComparator:^NSComparisonResult(NSValue *a, NSValue *b) {
        struct space_workflow_space *sa = a.pointerValue;
        struct space_workflow_space *sb = b.pointerValue;

        switch (g_status_island_workspace_order) {
        case STATUS_ISLAND_ORDER_ALPHABETICAL: {
            NSString *na = sa->label && *sa->label
                         ? [NSString stringWithUTF8String:sa->label]
                         : [NSString stringWithFormat:@"Space %d", sa->index];
            NSString *nb = sb->label && *sb->label
                         ? [NSString stringWithUTF8String:sb->label]
                         : [NSString stringWithFormat:@"Space %d", sb->index];
            return [na caseInsensitiveCompare:nb];
        }
        case STATUS_ISLAND_ORDER_CREATION:
            return sa->sid < sb->sid ? NSOrderedAscending
                 : sa->sid > sb->sid ? NSOrderedDescending : NSOrderedSame;
        case STATUS_ISLAND_ORDER_INDEX:
        default:
            return sa->index < sb->index ? NSOrderedAscending
                 : sa->index > sb->index ? NSOrderedDescending : NSOrderedSame;
        }
    }];

    for (NSValue *value in remaining) {
        [_space_items addObject:[self spaceItemForSpace:value.pointerValue]];
    }

    _focused_sid = current_sid;
    _focused_layout = current_layout;

    NSString *workspace_name = @"";
    if (current_sid) {
        for (int i = 0; i < snapshot->count; ++i) {
            if (snapshot->spaces[i].sid == current_sid) {
                workspace_name = snapshot->spaces[i].label && *snapshot->spaces[i].label
                               ? [NSString stringWithUTF8String:snapshot->spaces[i].label]
                               : [NSString stringWithFormat:@"Space %d", current_index];
                break;
            }
        }
    }

    [_workspace_wing setLabelText:workspace_name];
    [_layout_wing setSymbolName:[self layoutSymbolName:current_layout]];
    [_layout_wing setLabelText:[self layoutName:current_layout]];

    CGFloat newWingWidth = [self workspaceWingWidthForName:workspace_name];
    if (fabs(newWingWidth - oldWingWidth) > 0.5f) {
        _workspace_wing_width = newWingWidth;
        if (existed && !_collapsed) {
            [self applyStretchFrameAnimated];
        } else {
            [self applyFrameAnimated:NO];
            [self layoutWings];
        }
    }

    [self invalidateMenus];
    [_shadow_panel orderFrontRegardless];
    [_panel orderFrontRegardless];
}

- (void)updateCollapsedForMouse:(NSPoint)mouse
{
    if (!_panel || !_screen) return;

    NSRect screen_frame = _screen.frame;
    bool on_display = mouse.x >= NSMinX(screen_frame) && mouse.x < NSMaxX(screen_frame) &&
                      mouse.y >= NSMinY(screen_frame) && mouse.y <= NSMaxY(screen_frame);

    status_island_geometry g = [self geometry];
    CGPoint point = NSPointToCGPoint(mouse);
    bool over_menu = (_workspace_menu && _workspace_menu.visible && NSPointInRect(mouse, _workspace_menu.frame)) ||
                     (_layout_menu && _layout_menu.visible && NSPointInRect(mouse, _layout_menu.frame));

    bool collapsed = on_display && status_island_should_collapse_for_point(point, g) && !over_menu;
    [self setCollapsed:collapsed];
}
@end

@interface status_island_controller : NSObject {
    NSMutableDictionary *_islands;
    id _mouse_monitor;
    id _local_mouse_monitor;
}
+ (instancetype)sharedController;
- (void)refreshWithSnapshot:(struct space_workflow_snapshot *)snapshot;
- (void)hide;
- (void)screenParametersChanged:(NSNotification *)note;
@end

@implementation status_island_controller
+ (instancetype)sharedController
{
    static status_island_controller *controller;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        controller = [[status_island_controller alloc] init];
    });
    return controller;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _islands = [[NSMutableDictionary alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(screenParametersChanged:)
                                                     name:NSApplicationDidChangeScreenParametersNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (_mouse_monitor) [NSEvent removeMonitor:_mouse_monitor];
    if (_local_mouse_monitor) [NSEvent removeMonitor:_local_mouse_monitor];
    [_islands release];
    [super dealloc];
}

- (void)screenParametersChanged:(NSNotification *)__unused note
{
    status_island_invalidate();
}

- (void)refreshWithSnapshot:(struct space_workflow_snapshot *)snapshot
{
    NSMutableSet *seen = [NSMutableSet set];
    for (int i = 0; i < snapshot->display_count; ++i) {
        uint32_t did = snapshot->displays[i];
        NSNumber *key = [NSNumber numberWithUnsignedInt:did];
        [seen addObject:key];

        status_island *island = [_islands objectForKey:key];
        if (!island) {
            island = [[status_island alloc] initWithDisplayID:did];
            [_islands setObject:island forKey:key];
            [island release];
        }
        [island updateWithSnapshot:snapshot];
    }

    NSArray *keys = [_islands.allKeys copy];
    for (NSNumber *key in keys) {
        if (![seen containsObject:key]) {
            status_island *island = _islands[key];
            [island hide];
            [_islands removeObjectForKey:key];
        }
    }
    [keys release];

    [self addMouseMonitor];
}

- (void)hide
{
    for (status_island *island in _islands.allValues) {
        [island hide];
    }
}

- (void)addMouseMonitor
{
    if (!_mouse_monitor) {
        _mouse_monitor = [NSEvent addGlobalMonitorForEventsMatchingMask:NSEventMaskMouseMoved | NSEventMaskLeftMouseDragged | NSEventMaskRightMouseDragged
                                                                handler:^(NSEvent *__unused event) {
            [self updateCollapsedForMouse];
        }];
    }

    // Global monitors do not observe events delivered to this process, so a
    // non-consuming local monitor covers entry into/exit from island windows.
    if (!_local_mouse_monitor) {
        _local_mouse_monitor = [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskMouseMoved | NSEventMaskLeftMouseDragged | NSEventMaskRightMouseDragged
                                                                     handler:^(NSEvent *event) {
            [self updateCollapsedForMouse];
            return event;
        }];
    }
}

- (void)updateCollapsedForMouse
{
    NSPoint mouse = [NSEvent mouseLocation];
    for (status_island *island in _islands.allValues) {
        [island updateCollapsedForMouse:mouse];
    }
}
@end

bool status_island_is_enabled(void)
{
    return g_status_island_enabled;
}

void status_island_set_enabled(bool enabled)
{
    if (g_status_island_enabled == enabled) return;
    g_status_island_enabled = enabled;

    if (enabled) {
        status_island_invalidate();
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[status_island_controller sharedController] hide];
        });
    }
}

void status_island_set_workspace_order(enum status_island_workspace_order order)
{
    g_status_island_workspace_order = order;
    status_island_invalidate();
}

void status_island_invalidate(void)
{
    if (!g_status_island_enabled) return;

    if (!__atomic_exchange_n(&g_status_island_dirty, true, __ATOMIC_ACQ_REL)) {
        event_loop_post(&g_event_loop, STATUS_ISLAND_REFRESH, NULL, 0);
    }
}

void status_island_refresh(void)
{
    __atomic_store_n(&g_status_island_dirty, false, __ATOMIC_RELEASE);

    if (!g_status_island_enabled) return;

    struct space_workflow_snapshot *snapshot = space_workflow_create_space_snapshot();
    if (!snapshot) return;

    dispatch_async(dispatch_get_main_queue(), ^{
        [[status_island_controller sharedController] refreshWithSnapshot:snapshot];
        space_workflow_destroy_snapshot(snapshot);
    });
}
