extern int g_connection;
extern struct event_loop g_event_loop;
extern struct space_manager g_space_manager;
extern struct window_manager g_window_manager;

#define STACK_SELECTOR_WIDTH 28.0f
#define STACK_SELECTOR_ROW_HEIGHT 28.0f
#define STACK_SELECTOR_MIN_ROW_HEIGHT 8.0f
#define STACK_SELECTOR_PREVIEW_DELAY_SECONDS 0.2f
#define STACK_SELECTOR_PREVIEW_GAP 8.0f
#define STACK_SELECTOR_PREVIEW_MAX_WIDTH 360.0f
#define STACK_SELECTOR_PREVIEW_MAX_HEIGHT 220.0f
#define STACK_SELECTOR_PREVIEW_METADATA_HEIGHT 44.0f
#define STACK_SELECTOR_PREVIEW_MIN_WIDTH 240.0f

bool g_stack_selector_enabled = false;
enum stack_selector_anchor g_stack_selector_default_anchor = STACK_SELECTOR_ANCHOR_VERTICAL_CENTER_LEFT;
char *g_stack_selector_anchor_str[] =
{
    "vertical-top-left",
    "vertical-center-left",
    "vertical-bottom-left",
    "vertical-top-right",
    "vertical-center-right",
    "vertical-bottom-right",
    "horizontal-left-top",
    "horizontal-center-top",
    "horizontal-right-top",
    "horizontal-left-bottom",
    "horizontal-center-bottom",
    "horizontal-right-bottom",
};
static uint64_t g_stack_selector_next_id = 1;

@interface stack_selector_panel : NSPanel {
    enum stack_selector_anchor _stackSelectorAnchor;
}
@property enum stack_selector_anchor stackSelectorAnchor;
@end

@implementation stack_selector_panel
@synthesize stackSelectorAnchor = _stackSelectorAnchor;
- (BOOL)canBecomeKeyWindow
{
    return NO;
}

- (BOOL)canBecomeMainWindow
{
    return NO;
}
@end

static void stack_selector_hover_changed(uint64_t selector_id, uint32_t window_id, pid_t pid);

static inline bool stack_selector_anchor_is_horizontal(enum stack_selector_anchor anchor)
{
    return anchor >= STACK_SELECTOR_ANCHOR_HORIZONTAL_LEFT_TOP;
}

static inline bool stack_selector_anchor_is_left(enum stack_selector_anchor anchor)
{
    return anchor == STACK_SELECTOR_ANCHOR_VERTICAL_TOP_LEFT ||
           anchor == STACK_SELECTOR_ANCHOR_VERTICAL_CENTER_LEFT ||
           anchor == STACK_SELECTOR_ANCHOR_VERTICAL_BOTTOM_LEFT;
}

static inline bool stack_selector_anchor_is_top(enum stack_selector_anchor anchor)
{
    return anchor == STACK_SELECTOR_ANCHOR_HORIZONTAL_LEFT_TOP ||
           anchor == STACK_SELECTOR_ANCHOR_HORIZONTAL_CENTER_TOP ||
           anchor == STACK_SELECTOR_ANCHOR_HORIZONTAL_RIGHT_TOP;
}

#define STACK_SELECTOR_PICKER_PADDING 6.0f
#define STACK_SELECTOR_PICKER_CELL_WIDTH 58.0f
#define STACK_SELECTOR_PICKER_CELL_HEIGHT 42.0f
#define STACK_SELECTOR_PICKER_GAP 4.0f
#define STACK_SELECTOR_PICKER_FOOTER_HEIGHT 32.0f
#define STACK_SELECTOR_PICKER_WIDTH (STACK_SELECTOR_PICKER_PADDING * 2.0f + STACK_SELECTOR_PICKER_CELL_WIDTH * 3.0f + STACK_SELECTOR_PICKER_GAP * 2.0f)
#define STACK_SELECTOR_PICKER_GRID_HEIGHT (STACK_SELECTOR_PICKER_CELL_HEIGHT * 4.0f + STACK_SELECTOR_PICKER_GAP * 3.0f)
#define STACK_SELECTOR_PICKER_HEIGHT (STACK_SELECTOR_PICKER_PADDING * 3.0f + STACK_SELECTOR_PICKER_GRID_HEIGHT + 1.0f + STACK_SELECTOR_PICKER_FOOTER_HEIGHT)

@interface stack_selector_anchor_picker_view : NSView {
    enum stack_selector_anchor _anchor;
    bool _anchor_override;
    uint32_t _window_id;
    NSInteger _hovered_index;
    NSTrackingArea *_tracking_area;
}
- (instancetype)initWithAnchor:(enum stack_selector_anchor)anchor
                anchorOverride:(bool)anchor_override
                      windowId:(uint32_t)window_id;
- (NSRect)cellRectForIndex:(NSInteger)index;
- (NSRect)defaultRect;
@end

@implementation stack_selector_anchor_picker_view
- (instancetype)initWithAnchor:(enum stack_selector_anchor)anchor
                anchorOverride:(bool)anchor_override
                      windowId:(uint32_t)window_id
{
    self = [super initWithFrame:NSMakeRect(0, 0, STACK_SELECTOR_PICKER_WIDTH, STACK_SELECTOR_PICKER_HEIGHT)];
    if (self) {
        _anchor = anchor;
        _anchor_override = anchor_override;
        _window_id = window_id;
        _hovered_index = -1;

        for (NSInteger index = 0; index < STACK_SELECTOR_ANCHOR_COUNT; ++index) {
            [self addToolTipRect:[self cellRectForIndex:index]
                           owner:self
                        userData:(void *)(intptr_t)(index + 1)];
        }
        [self addToolTipRect:[self defaultRect]
                       owner:self
                    userData:(void *)(intptr_t)(STACK_SELECTOR_ANCHOR_COUNT + 1)];
    }
    return self;
}

- (void)dealloc
{
    if (_tracking_area) {
        [self removeTrackingArea:_tracking_area];
        [_tracking_area release];
    }
    [super dealloc];
}

- (BOOL)isFlipped
{
    return YES;
}

- (BOOL)acceptsFirstMouse:(NSEvent *)event
{
    return YES;
}

- (NSRect)cellRectForIndex:(NSInteger)index
{
    NSInteger row = index / 3;
    NSInteger column = index % 3;
    return NSMakeRect(STACK_SELECTOR_PICKER_PADDING + column * (STACK_SELECTOR_PICKER_CELL_WIDTH + STACK_SELECTOR_PICKER_GAP),
                      STACK_SELECTOR_PICKER_PADDING + row * (STACK_SELECTOR_PICKER_CELL_HEIGHT + STACK_SELECTOR_PICKER_GAP),
                      STACK_SELECTOR_PICKER_CELL_WIDTH,
                      STACK_SELECTOR_PICKER_CELL_HEIGHT);
}

- (NSRect)defaultRect
{
    return NSMakeRect(STACK_SELECTOR_PICKER_PADDING,
                      STACK_SELECTOR_PICKER_PADDING * 2.0f + STACK_SELECTOR_PICKER_GRID_HEIGHT + 1.0f,
                      STACK_SELECTOR_PICKER_WIDTH - STACK_SELECTOR_PICKER_PADDING * 2.0f,
                      STACK_SELECTOR_PICKER_FOOTER_HEIGHT);
}

- (NSInteger)indexAtPoint:(NSPoint)point
{
    for (NSInteger index = 0; index < STACK_SELECTOR_ANCHOR_COUNT; ++index) {
        if (NSPointInRect(point, [self cellRectForIndex:index])) return index;
    }
    return NSPointInRect(point, [self defaultRect]) ? STACK_SELECTOR_ANCHOR_COUNT : -1;
}

- (NSString *)view:(NSView *)view
  stringForToolTip:(NSToolTipTag)tag
             point:(NSPoint)point
          userData:(void *)user_data
{
    NSInteger index = (NSInteger)(intptr_t)user_data - 1;
    return index == STACK_SELECTOR_ANCHOR_COUNT
         ? @"Use global default"
         : [NSString stringWithUTF8String:g_stack_selector_anchor_str[index]];
}

- (void)updateTrackingAreas
{
    if (_tracking_area) {
        [self removeTrackingArea:_tracking_area];
        [_tracking_area release];
    }

    _tracking_area = [[NSTrackingArea alloc] initWithRect:self.bounds
                                                  options:NSTrackingActiveAlways | NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingInVisibleRect
                                                    owner:self
                                                 userInfo:nil];
    [self addTrackingArea:_tracking_area];
    [super updateTrackingAreas];
}

- (void)mouseMoved:(NSEvent *)event
{
    NSInteger index = [self indexAtPoint:[self convertPoint:event.locationInWindow fromView:nil]];
    if (_hovered_index != index) {
        _hovered_index = index;
        [self setNeedsDisplay:YES];
    }
}

- (void)mouseEntered:(NSEvent *)event
{
    [self mouseMoved:event];
}

- (void)mouseExited:(NSEvent *)event
{
    _hovered_index = -1;
    [self setNeedsDisplay:YES];
}

- (void)mouseDown:(NSEvent *)event
{
    NSInteger index = [self indexAtPoint:[self convertPoint:event.locationInWindow fromView:nil]];
    if (index < 0) return;

    event_loop_post(&g_event_loop,
                    STACK_SELECTOR_ANCHOR_CHANGED,
                    (void *)(uintptr_t)_window_id,
                    (int)index);
    [self.enclosingMenuItem.menu cancelTracking];
}

- (void)drawAnchor:(enum stack_selector_anchor)anchor inRect:(NSRect)rect
{
    NSRect window_rect = NSMakeRect(NSMidX(rect) - 19.0f, NSMidY(rect) - 13.0f, 38.0f, 26.0f);
    NSBezierPath *window = [NSBezierPath bezierPathWithRoundedRect:window_rect xRadius:4.0f yRadius:4.0f];
    [[[NSColor labelColor] colorWithAlphaComponent:0.68f] setStroke];
    window.lineWidth = 1.25f;
    [window stroke];

    NSPoint start;
    NSPoint end;
    if (!stack_selector_anchor_is_horizontal(anchor)) {
        NSInteger alignment = anchor % 3;
        CGFloat y = alignment == 0
                  ? NSMinY(window_rect) + 3.0f
                  : alignment == 1
                  ? NSMidY(window_rect) - 5.0f
                  : NSMaxY(window_rect) - 13.0f;
        CGFloat x = stack_selector_anchor_is_left(anchor)
                  ? NSMinX(window_rect) + 1.0f
                  : NSMaxX(window_rect) - 1.0f;
        start = NSMakePoint(x, y);
        end = NSMakePoint(x, y + 10.0f);
    } else {
        NSInteger alignment = (anchor - STACK_SELECTOR_ANCHOR_HORIZONTAL_LEFT_TOP) % 3;
        CGFloat x = alignment == 0
                  ? NSMinX(window_rect) + 3.0f
                  : alignment == 1
                  ? NSMidX(window_rect) - 5.0f
                  : NSMaxX(window_rect) - 13.0f;
        CGFloat y = stack_selector_anchor_is_top(anchor)
                  ? NSMinY(window_rect) + 1.0f
                  : NSMaxY(window_rect) - 1.0f;
        start = NSMakePoint(x, y);
        end = NSMakePoint(x + 10.0f, y);
    }

    NSBezierPath *rail = [NSBezierPath bezierPath];
    [rail moveToPoint:start];
    [rail lineToPoint:end];
    rail.lineWidth = 4.5f;
    rail.lineCapStyle = NSLineCapStyleRound;
    [[NSColor controlAccentColor] setStroke];
    [rail stroke];

    [[NSColor whiteColor] setFill];
    for (int index = 1; index <= 3; ++index) {
        CGFloat progress = index / 4.0f;
        NSPoint point = NSMakePoint(start.x + (end.x - start.x) * progress,
                                   start.y + (end.y - start.y) * progress);
        [[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(point.x - 1.0f, point.y - 1.0f, 2.0f, 2.0f)] fill];
    }
}

- (void)drawDefaultInRect:(NSRect)rect
{
    NSImage *reset = [NSImage imageWithSystemSymbolName:@"arrow.counterclockwise"
                              accessibilityDescription:@"Use global default"];
    reset = [reset imageWithSymbolConfiguration:[NSImageSymbolConfiguration configurationWithPointSize:14.0f
                                                                                                 weight:NSFontWeightMedium]];
    [reset drawInRect:NSMakeRect(NSMidX(rect) - 8.0f, NSMidY(rect) - 8.0f, 16.0f, 16.0f)];
}

- (void)drawRect:(NSRect)dirty_rect
{
    [super drawRect:dirty_rect];

    for (NSInteger index = 0; index < STACK_SELECTOR_ANCHOR_COUNT; ++index) {
        NSRect cell_rect = [self cellRectForIndex:index];
        bool selected = _anchor_override && index == _anchor;
        if (selected || index == _hovered_index) {
            NSColor *fill = selected
                          ? [[NSColor controlAccentColor] colorWithAlphaComponent:0.28f]
                          : [[NSColor labelColor] colorWithAlphaComponent:0.10f];
            [fill setFill];
            [[NSBezierPath bezierPathWithRoundedRect:cell_rect xRadius:8.0f yRadius:8.0f] fill];
        }
        [self drawAnchor:index inRect:cell_rect];
    }

    CGFloat divider_y = STACK_SELECTOR_PICKER_PADDING + STACK_SELECTOR_PICKER_GRID_HEIGHT + STACK_SELECTOR_PICKER_PADDING / 2.0f;
    [[[NSColor separatorColor] colorWithAlphaComponent:0.70f] setStroke];
    NSBezierPath *divider = [NSBezierPath bezierPath];
    [divider moveToPoint:NSMakePoint(STACK_SELECTOR_PICKER_PADDING, divider_y)];
    [divider lineToPoint:NSMakePoint(STACK_SELECTOR_PICKER_WIDTH - STACK_SELECTOR_PICKER_PADDING, divider_y)];
    divider.lineWidth = 1.0f;
    [divider stroke];

    NSRect default_rect = [self defaultRect];
    NSBezierPath *default_button = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect(default_rect, 0.5f, 0.5f)
                                                                   xRadius:7.0f
                                                                   yRadius:7.0f];
    if (!_anchor_override || _hovered_index == STACK_SELECTOR_ANCHOR_COUNT) {
        NSColor *fill = !_anchor_override
                      ? [[NSColor controlAccentColor] colorWithAlphaComponent:0.22f]
                      : [[NSColor labelColor] colorWithAlphaComponent:0.10f];
        [fill setFill];
        [default_button fill];
    }
    NSColor *border = !_anchor_override
                    ? [[NSColor controlAccentColor] colorWithAlphaComponent:0.70f]
                    : [[NSColor separatorColor] colorWithAlphaComponent:0.70f];
    [border setStroke];
    default_button.lineWidth = 1.0f;
    [default_button stroke];
    [self drawDefaultInRect:default_rect];
}
@end

@interface stack_selector_view : NSView {
    NSArray *_window_ids;
    NSArray *_pids;
    NSArray *_icons;
    uint64_t _selector_id;
    uint32_t _active_window_id;
    enum stack_selector_anchor _anchor;
    bool _anchor_override;
    bool _horizontal;
    NSInteger _hovered_index;
    NSTrackingArea *_tracking_area;
}
- (instancetype)initWithFrame:(NSRect)frame selectorId:(uint64_t)selector_id;
- (void)updateWithWindowIds:(NSArray *)window_ids
                       pids:(NSArray *)pids
             activeWindowId:(uint32_t)active_window_id
                     anchor:(enum stack_selector_anchor)anchor
             anchorOverride:(bool)anchor_override;
@end

@implementation stack_selector_view
- (instancetype)initWithFrame:(NSRect)frame selectorId:(uint64_t)selector_id
{
    self = [super initWithFrame:frame];
    if (self) {
        _selector_id = selector_id;
        _hovered_index = -1;
    }
    return self;
}

- (void)dealloc
{
    if (_tracking_area) {
        [self removeTrackingArea:_tracking_area];
        [_tracking_area release];
    }
    [_window_ids release];
    [_pids release];
    [_icons release];
    [super dealloc];
}

- (BOOL)isFlipped
{
    return YES;
}

- (BOOL)acceptsFirstMouse:(NSEvent *)event
{
    return YES;
}

- (void)updateTrackingAreas
{
    if (_tracking_area) {
        [self removeTrackingArea:_tracking_area];
        [_tracking_area release];
    }

    _tracking_area = [[NSTrackingArea alloc] initWithRect:self.bounds
                                                  options:NSTrackingActiveAlways | NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingInVisibleRect
                                                    owner:self
                                                 userInfo:nil];
    [self addTrackingArea:_tracking_area];
    [super updateTrackingAreas];
}

- (void)updateWithWindowIds:(NSArray *)window_ids
                       pids:(NSArray *)pids
             activeWindowId:(uint32_t)active_window_id
                     anchor:(enum stack_selector_anchor)anchor
             anchorOverride:(bool)anchor_override
{
    uint32_t previous_hovered_window_id = _hovered_index >= 0 && _hovered_index < (NSInteger)_window_ids.count
                                        ? [_window_ids[_hovered_index] unsignedIntValue]
                                        : 0;

    [_window_ids release];
    _window_ids = [window_ids copy];
    [_pids release];
    _pids = [pids copy];
    _active_window_id = active_window_id;
    _anchor = anchor;
    _anchor_override = anchor_override;
    _horizontal = stack_selector_anchor_is_horizontal(anchor);

    NSMutableArray *icons = [NSMutableArray arrayWithCapacity:pids.count];
    for (NSNumber *pid_number in pids) {
        NSImage *icon = nil;
        pid_t pid = (pid_t)pid_number.intValue;
        if (pid) {
            NSRunningApplication *application = [NSRunningApplication runningApplicationWithProcessIdentifier:pid];
            icon = application.icon;
        }
        if (!icon) {
            icon = [NSImage imageWithSystemSymbolName:@"macwindow" accessibilityDescription:@"Window"];
        }
        [icons addObject:icon ?: (id)[NSNull null]];
    }

    [_icons release];
    _icons = [icons copy];

    uint32_t hovered_window_id = _hovered_index >= 0 && _hovered_index < (NSInteger)_window_ids.count
                               ? [_window_ids[_hovered_index] unsignedIntValue]
                               : 0;
    if (hovered_window_id != previous_hovered_window_id) {
        _hovered_index = -1;
        stack_selector_hover_changed(_selector_id, 0, 0);
    } else if (hovered_window_id == _active_window_id) {
        stack_selector_hover_changed(_selector_id, 0, 0);
    }
    [self setNeedsDisplay:YES];
}

- (NSInteger)indexAtPoint:(NSPoint)point
{
    if (!_window_ids.count || !NSPointInRect(point, self.bounds)) return -1;

    CGFloat item_extent = _horizontal
                        ? self.bounds.size.width / _window_ids.count
                        : self.bounds.size.height / _window_ids.count;
    NSInteger index = floor((_horizontal ? point.x : point.y) / item_extent);
    return index >= 0 && index < (NSInteger)_window_ids.count ? index : -1;
}

- (void)mouseMoved:(NSEvent *)event
{
    NSInteger index = [self indexAtPoint:[self convertPoint:event.locationInWindow fromView:nil]];
    if (_hovered_index != index) {
        _hovered_index = index;
        [self setNeedsDisplay:YES];

        uint32_t window_id = index >= 0 ? [_window_ids[index] unsignedIntValue] : 0;
        pid_t pid = index >= 0 && index < (NSInteger)_pids.count ? (pid_t)[_pids[index] intValue] : 0;
        if (window_id == _active_window_id) {
            window_id = 0;
            pid = 0;
        }
        stack_selector_hover_changed(_selector_id, window_id, pid);
    }
}

- (void)mouseEntered:(NSEvent *)event
{
    [self mouseMoved:event];
}

- (void)mouseExited:(NSEvent *)event
{
    if (_hovered_index != -1) {
        _hovered_index = -1;
        [self setNeedsDisplay:YES];
        stack_selector_hover_changed(_selector_id, 0, 0);
    }
}

- (void)mouseDown:(NSEvent *)event
{
    NSInteger index = [self indexAtPoint:[self convertPoint:event.locationInWindow fromView:nil]];
    if (index < 0) return;

    uint32_t window_id = [_window_ids[index] unsignedIntValue];
    stack_selector_hover_changed(_selector_id, 0, 0);
    event_loop_post(&g_event_loop, STACK_SELECTOR_SELECTED, (void *)(uintptr_t)window_id, 0);
}

- (void)rightMouseDown:(NSEvent *)event
{
    NSMenu *menu = [[[NSMenu alloc] initWithTitle:@"Stack Selector Anchor"] autorelease];
    menu.autoenablesItems = NO;

    stack_selector_anchor_picker_view *picker = [[stack_selector_anchor_picker_view alloc] initWithAnchor:_anchor
                                                                                           anchorOverride:_anchor_override
                                                                                                 windowId:_active_window_id];
    NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:@"" action:nil keyEquivalent:@""];
    item.view = picker;
    [menu addItem:item];
    [picker release];
    [item release];

    stack_selector_hover_changed(_selector_id, 0, 0);
    [NSMenu popUpContextMenu:menu withEvent:event forView:self];
}

- (void)drawRect:(NSRect)dirty_rect
{
    [super drawRect:dirty_rect];

    CGFloat item_extent = !_window_ids.count
                        ? 0
                        : _horizontal
                        ? self.bounds.size.width / _window_ids.count
                        : self.bounds.size.height / _window_ids.count;
    for (NSInteger index = 0; index < (NSInteger)_window_ids.count; ++index) {
        NSRect row_rect = _horizontal
                        ? NSMakeRect(index * item_extent, 0, item_extent, self.bounds.size.height)
                        : NSMakeRect(0, index * item_extent, self.bounds.size.width, item_extent);
        uint32_t window_id = [_window_ids[index] unsignedIntValue];
        bool is_active = window_id == _active_window_id;
        bool is_hovered = index == _hovered_index;

        if (is_active || is_hovered) {
            NSRect selection_rect = NSInsetRect(row_rect, 1.5f, 1.5f);
            NSBezierPath *selection = [NSBezierPath bezierPathWithRoundedRect:selection_rect xRadius:5.0f yRadius:5.0f];
            NSColor *fill = is_active
                          ? [[NSColor controlAccentColor] colorWithAlphaComponent:0.28f]
                          : [[NSColor controlAccentColor] colorWithAlphaComponent:0.12f];
            [fill setFill];
            [selection fill];

            if (is_active) {
                [[[NSColor labelColor] colorWithAlphaComponent:0.65f] setStroke];
                selection.lineWidth = 1.0f;
                [selection stroke];
            }
        }

        id icon_value = index < (NSInteger)_icons.count ? _icons[index] : nil;
        if (icon_value && icon_value != [NSNull null]) {
            NSImage *icon = icon_value;
            CGFloat icon_size = MIN(20.0f, MAX(4.0f, MIN(row_rect.size.width, row_rect.size.height) - 8.0f));
            NSRect icon_rect = NSMakeRect(NSMidX(row_rect) - icon_size / 2.0f,
                                          NSMidY(row_rect) - icon_size / 2.0f,
                                          icon_size,
                                          icon_size);
            [icon drawInRect:icon_rect
                    fromRect:NSZeroRect
                   operation:NSCompositingOperationSourceOver
                    fraction:1.0f
              respectFlipped:YES
                       hints:nil];
        }
    }

}
@end

@interface stack_selector_preview_view : NSView {
    NSImage *_preview_image;
    NSImage *_app_icon;
    NSString *_app_name;
    NSString *_window_title;
}
- (void)updateWithImage:(CGImageRef)image
                   icon:(NSImage *)icon
                appName:(NSString *)app_name
                  title:(NSString *)window_title;
@end

@implementation stack_selector_preview_view
- (void)dealloc
{
    [_preview_image release];
    [_app_icon release];
    [_app_name release];
    [_window_title release];
    [super dealloc];
}

- (BOOL)isFlipped
{
    return YES;
}

- (void)updateWithImage:(CGImageRef)image
                   icon:(NSImage *)icon
                appName:(NSString *)app_name
                  title:(NSString *)window_title
{
    [_preview_image release];
    _preview_image = image ? [[NSImage alloc] initWithCGImage:image size:NSZeroSize] : nil;
    [_app_icon release];
    _app_icon = [icon retain];
    [_app_name release];
    _app_name = [app_name copy];
    [_window_title release];
    _window_title = [window_title copy];
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirty_rect
{
    [super drawRect:dirty_rect];

    CGFloat metadata_y = self.bounds.size.height - STACK_SELECTOR_PREVIEW_METADATA_HEIGHT;
    if (_preview_image) {
        NSRect available = NSMakeRect(8.0f,
                                      8.0f,
                                      self.bounds.size.width - 16.0f,
                                      MAX(1.0f, metadata_y - 12.0f));
        NSSize image_size = _preview_image.size;
        CGFloat scale = MIN(available.size.width / image_size.width,
                            available.size.height / image_size.height);
        NSSize fitted = NSMakeSize(floor(image_size.width * scale), floor(image_size.height * scale));
        NSRect image_rect = NSMakeRect(NSMidX(available) - fitted.width / 2.0f,
                                       NSMidY(available) - fitted.height / 2.0f,
                                       fitted.width,
                                       fitted.height);
        [NSGraphicsContext saveGraphicsState];
        [[NSBezierPath bezierPathWithRoundedRect:image_rect xRadius:6.0f yRadius:6.0f] addClip];
        [_preview_image drawInRect:image_rect
                         fromRect:NSZeroRect
                        operation:NSCompositingOperationSourceOver
                         fraction:1.0f
                   respectFlipped:YES
                            hints:nil];
        [NSGraphicsContext restoreGraphicsState];
    }

    CGFloat icon_size = 24.0f;
    NSRect icon_rect = NSMakeRect(10.0f,
                                  metadata_y + (STACK_SELECTOR_PREVIEW_METADATA_HEIGHT - icon_size) / 2.0f,
                                  icon_size,
                                  icon_size);
    [_app_icon drawInRect:icon_rect
                 fromRect:NSZeroRect
                operation:NSCompositingOperationSourceOver
                 fraction:1.0f
           respectFlipped:YES
                    hints:nil];

    NSMutableParagraphStyle *paragraph = [[[NSMutableParagraphStyle alloc] init] autorelease];
    paragraph.lineBreakMode = NSLineBreakByTruncatingTail;
    NSDictionary *app_attributes = @{
        NSFontAttributeName: [NSFont systemFontOfSize:11.0f weight:NSFontWeightSemibold],
        NSForegroundColorAttributeName: NSColor.labelColor,
        NSParagraphStyleAttributeName: paragraph
    };
    NSDictionary *title_attributes = @{
        NSFontAttributeName: [NSFont systemFontOfSize:10.0f],
        NSForegroundColorAttributeName: NSColor.secondaryLabelColor,
        NSParagraphStyleAttributeName: paragraph
    };
    CGFloat text_x = NSMaxX(icon_rect) + 8.0f;
    CGFloat text_width = self.bounds.size.width - text_x - 10.0f;
    [_app_name drawInRect:NSMakeRect(text_x, metadata_y + 7.0f, text_width, 15.0f)
           withAttributes:app_attributes];
    [_window_title drawInRect:NSMakeRect(text_x, metadata_y + 22.0f, text_width, 14.0f)
               withAttributes:title_attributes];
}
@end

@interface stack_selector_controller : NSObject {
    NSMutableDictionary *_panels;
    stack_selector_panel *_preview_panel;
    uint64_t _preview_generation;
    uint64_t _hovered_selector_id;
    uint32_t _hovered_window_id;
}
+ (instancetype)sharedController;
- (void)updateSelector:(uint64_t)selector_id
                 frame:(CGRect)frame
             windowIds:(NSArray *)window_ids
                  pids:(NSArray *)pids
        activeWindowId:(uint32_t)active_window_id
                anchor:(enum stack_selector_anchor)anchor
        anchorOverride:(bool)anchor_override API_AVAILABLE(macos(27.0));
- (void)removeSelector:(uint64_t)selector_id;
- (void)hoverSelector:(uint64_t)selector_id windowId:(uint32_t)window_id pid:(pid_t)pid;
- (void)showPreviewForSelector:(uint64_t)selector_id
                      windowId:(uint32_t)window_id
                         image:(CGImageRef)image
                          icon:(NSImage *)icon
                       appName:(NSString *)app_name
                         title:(NSString *)window_title API_AVAILABLE(macos(27.0));
- (void)hidePreview;
- (void)hideAll;
@end

@implementation stack_selector_controller
+ (instancetype)sharedController
{
    static stack_selector_controller *controller;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        controller = [[stack_selector_controller alloc] init];
    });
    return controller;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _panels = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)dealloc
{
    for (stack_selector_panel *panel in _panels.allValues) {
        [panel close];
    }
    [_preview_panel close];
    [_preview_panel release];
    [_panels release];
    [super dealloc];
}

- (void)updateSelector:(uint64_t)selector_id
                 frame:(CGRect)frame
             windowIds:(NSArray *)window_ids
                  pids:(NSArray *)pids
        activeWindowId:(uint32_t)active_window_id
                anchor:(enum stack_selector_anchor)anchor
        anchorOverride:(bool)anchor_override
{
    NSNumber *key = [NSNumber numberWithUnsignedLongLong:selector_id];
    stack_selector_panel *panel = [_panels objectForKey:key];
    if (!panel) {
        panel = [[stack_selector_panel alloc] initWithContentRect:frame
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
        panel.collectionBehavior = NSWindowCollectionBehaviorTransient | NSWindowCollectionBehaviorFullScreenAuxiliary | NSWindowCollectionBehaviorIgnoresCycle;

        stack_selector_view *view = [[stack_selector_view alloc] initWithFrame:NSMakeRect(0, 0, frame.size.width, frame.size.height)
                                                                     selectorId:selector_id];
        view.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;

        NSGlassEffectView *surface = [[NSGlassEffectView alloc] initWithFrame:NSMakeRect(0, 0, frame.size.width, frame.size.height)];
        surface.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        surface.style = NSGlassEffectViewStyleRegular;
        surface.cornerRadius = 8.0f;
        surface.tintColor = nil;
        surface.effectIsInteractive = YES;
        surface.contentView = view;
        panel.contentView = surface;
        [view release];
        [surface release];

        [_panels setObject:panel forKey:key];
        [panel release];
    }

    panel.stackSelectorAnchor = anchor;
    [panel setFrame:frame display:NO];
    NSGlassEffectView *surface = (NSGlassEffectView *)panel.contentView;
    surface.frame = NSMakeRect(0, 0, frame.size.width, frame.size.height);
    stack_selector_view *view = (stack_selector_view *)surface.contentView;
    [view updateWithWindowIds:window_ids
                         pids:pids
               activeWindowId:active_window_id
                       anchor:anchor
               anchorOverride:anchor_override];

    [panel orderFrontRegardless];
    uint32_t selector_window_id = (uint32_t)panel.windowNumber;
    SLSSetWindowLevel(g_connection, selector_window_id, window_level(active_window_id));
    SLSSetWindowSubLevel(g_connection, selector_window_id, window_sub_level(active_window_id) + 1);
    SLSOrderWindow(g_connection, selector_window_id, 1, active_window_id);
}

- (void)hoverSelector:(uint64_t)selector_id windowId:(uint32_t)window_id pid:(pid_t)pid
{
    [self hidePreview];
    if (!window_id || ![_panels objectForKey:[NSNumber numberWithUnsignedLongLong:selector_id]]) return;

    _hovered_selector_id = selector_id;
    _hovered_window_id = window_id;
    uint64_t generation = _preview_generation;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(STACK_SELECTOR_PREVIEW_DELAY_SECONDS * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        if (generation != self->_preview_generation ||
            selector_id != self->_hovered_selector_id ||
            window_id != self->_hovered_window_id) return;

        NSRunningApplication *application = pid
                                          ? [NSRunningApplication runningApplicationWithProcessIdentifier:pid]
                                          : nil;
        NSString *app_name = application.localizedName ?: @"Window";
        NSImage *icon = application.icon;
        if (!icon) {
            icon = [NSImage imageWithSystemSymbolName:@"macwindow" accessibilityDescription:@"Window"];
        }

        NSString *window_title = @"";
        CFArrayRef info_ref = CGWindowListCopyWindowInfo(kCGWindowListOptionIncludingWindow, window_id);
        if (info_ref && CFArrayGetCount(info_ref) > 0) {
            CFDictionaryRef info = CFArrayGetValueAtIndex(info_ref, 0);
            CFStringRef title_ref = CFDictionaryGetValue(info, kCGWindowName);
            if (title_ref) window_title = [NSString stringWithString:(NSString *)title_ref];
        }
        if (info_ref) CFRelease(info_ref);

        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
            int capture_connection = 0;
            CGImageRef image = NULL;
            if (SLSNewConnection(0, &capture_connection) == kCGErrorSuccess) {
                uint32_t capture_window_id = window_id;
                CFArrayRef images = SLSHWCaptureWindowList(capture_connection,
                                                          &capture_window_id,
                                                          1,
                                                          (1 << 11) | (1 << 8));
                if (images && CFArrayGetCount(images) > 0) {
                    CFTypeRef value = CFArrayGetValueAtIndex(images, 0);
                    if (value && CFGetTypeID(value) == CGImageGetTypeID()) {
                        image = (CGImageRef)CFRetain(value);
                    }
                }
                if (images) CFRelease(images);
                SLSReleaseConnection(capture_connection);
            }

            dispatch_async(dispatch_get_main_queue(), ^{
                if (generation == self->_preview_generation &&
                    selector_id == self->_hovered_selector_id &&
                    window_id == self->_hovered_window_id) {
                    if (@available(macOS 27.0, *)) {
                        [self showPreviewForSelector:selector_id
                                           windowId:window_id
                                              image:image
                                               icon:icon
                                            appName:app_name
                                              title:window_title];
                    }
                }
                if (image) CGImageRelease(image);
            });
        });
    });
}

- (void)showPreviewForSelector:(uint64_t)selector_id
                      windowId:(uint32_t)window_id
                         image:(CGImageRef)image
                          icon:(NSImage *)icon
                       appName:(NSString *)app_name
                         title:(NSString *)window_title
{
    stack_selector_panel *selector_panel = [_panels objectForKey:[NSNumber numberWithUnsignedLongLong:selector_id]];
    if (!selector_panel) return;

    CGFloat thumbnail_width = 0;
    CGFloat thumbnail_height = 0;
    if (image) {
        CGFloat image_width = CGImageGetWidth(image);
        CGFloat image_height = CGImageGetHeight(image);
        CGFloat scale = MIN(STACK_SELECTOR_PREVIEW_MAX_WIDTH / image_width,
                            STACK_SELECTOR_PREVIEW_MAX_HEIGHT / image_height);
        thumbnail_width = floor(image_width * scale);
        thumbnail_height = floor(image_height * scale);
    }

    CGFloat panel_width = image ? MAX(STACK_SELECTOR_PREVIEW_MIN_WIDTH, thumbnail_width + 16.0f) : 300.0f;
    CGFloat panel_height = image ? thumbnail_height + STACK_SELECTOR_PREVIEW_METADATA_HEIGHT + 16.0f : 60.0f;
    NSSize panel_size = NSMakeSize(panel_width, panel_height);

    if (!_preview_panel) {
        _preview_panel = [[stack_selector_panel alloc] initWithContentRect:NSMakeRect(0, 0, panel_width, panel_height)
                                                                  styleMask:NSWindowStyleMaskBorderless | NSWindowStyleMaskNonactivatingPanel
                                                                    backing:NSBackingStoreBuffered
                                                                      defer:NO];
        _preview_panel.opaque = NO;
        _preview_panel.backgroundColor = NSColor.clearColor;
        _preview_panel.hasShadow = NO;
        _preview_panel.hidesOnDeactivate = NO;
        _preview_panel.releasedWhenClosed = NO;
        _preview_panel.ignoresMouseEvents = YES;
        _preview_panel.animationBehavior = NSWindowAnimationBehaviorNone;
        _preview_panel.collectionBehavior = NSWindowCollectionBehaviorTransient | NSWindowCollectionBehaviorFullScreenAuxiliary | NSWindowCollectionBehaviorIgnoresCycle;

        stack_selector_preview_view *preview_view = [[stack_selector_preview_view alloc] initWithFrame:NSMakeRect(0, 0, panel_width, panel_height)];
        preview_view.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;

        NSGlassEffectView *surface = [[NSGlassEffectView alloc] initWithFrame:NSMakeRect(0, 0, panel_width, panel_height)];
        surface.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        surface.style = NSGlassEffectViewStyleRegular;
        surface.cornerRadius = 12.0f;
        surface.tintColor = nil;
        surface.effectIsInteractive = NO;
        surface.contentView = preview_view;
        _preview_panel.contentView = surface;
        [preview_view release];
        [surface release];
    }

    NSRect selector_frame = selector_panel.frame;
    NSScreen *screen = selector_panel.screen;
    if (!screen) {
        for (NSScreen *candidate in NSScreen.screens) {
            if (NSIntersectsRect(candidate.frame, selector_frame)) {
                screen = candidate;
                break;
            }
        }
    }
    NSRect visible_frame = screen ? screen.visibleFrame : NSScreen.mainScreen.visibleFrame;
    enum stack_selector_anchor anchor = selector_panel.stackSelectorAnchor;
    CGFloat x;
    CGFloat y;
    if (stack_selector_anchor_is_horizontal(anchor)) {
        x = NSMidX(selector_frame) - panel_width / 2.0f;
        y = stack_selector_anchor_is_top(anchor)
          ? NSMinY(selector_frame) - STACK_SELECTOR_PREVIEW_GAP - panel_height
          : NSMaxY(selector_frame) + STACK_SELECTOR_PREVIEW_GAP;
    } else {
        x = stack_selector_anchor_is_left(anchor)
          ? NSMaxX(selector_frame) + STACK_SELECTOR_PREVIEW_GAP
          : NSMinX(selector_frame) - STACK_SELECTOR_PREVIEW_GAP - panel_width;
        y = NSMidY(selector_frame) - panel_height / 2.0f;
    }
    x = MIN(MAX(x, NSMinX(visible_frame)), NSMaxX(visible_frame) - panel_width);
    y = MIN(MAX(y, NSMinY(visible_frame)), NSMaxY(visible_frame) - panel_height);

    [_preview_panel setFrame:NSMakeRect(x, y, panel_size.width, panel_size.height) display:NO];
    NSGlassEffectView *surface = (NSGlassEffectView *)_preview_panel.contentView;
    surface.frame = NSMakeRect(0, 0, panel_width, panel_height);
    stack_selector_preview_view *preview_view = (stack_selector_preview_view *)surface.contentView;
    [preview_view updateWithImage:image icon:icon appName:app_name title:window_title];

    [_preview_panel orderFrontRegardless];
    uint32_t preview_window_id = (uint32_t)_preview_panel.windowNumber;
    uint32_t selector_window_id = (uint32_t)selector_panel.windowNumber;
    SLSSetWindowLevel(g_connection, preview_window_id, window_level(window_id));
    SLSSetWindowSubLevel(g_connection, preview_window_id, window_sub_level(window_id));
    SLSOrderWindow(g_connection, preview_window_id, 1, selector_window_id);
}

- (void)hidePreview
{
    ++_preview_generation;
    _hovered_selector_id = 0;
    _hovered_window_id = 0;
    [_preview_panel orderOut:nil];
}

- (void)removeSelector:(uint64_t)selector_id
{
    NSNumber *key = [NSNumber numberWithUnsignedLongLong:selector_id];
    stack_selector_panel *panel = [_panels objectForKey:key];
    if (!panel) return;

    if (_hovered_selector_id == selector_id) [self hidePreview];
    [panel orderOut:nil];
    [panel close];
    [_panels removeObjectForKey:key];
}

- (void)hideAll
{
    [self hidePreview];
    for (stack_selector_panel *panel in _panels.allValues) {
        [panel orderOut:nil];
    }
}
@end

static void stack_selector_hover_changed(uint64_t selector_id, uint32_t window_id, pid_t pid)
{
    [[stack_selector_controller sharedController] hoverSelector:selector_id windowId:window_id pid:pid];
}

static void stack_selector_dispatch_update(uint64_t selector_id,
                                           CGRect frame,
                                           NSArray *window_ids,
                                           NSArray *pids,
                                           uint32_t active_window_id,
                                           enum stack_selector_anchor anchor,
                                           bool anchor_override)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (@available(macOS 27.0, *)) {
            [[stack_selector_controller sharedController] updateSelector:selector_id
                                                                   frame:frame
                                                               windowIds:window_ids
                                                                    pids:pids
                                                          activeWindowId:active_window_id
                                                                  anchor:anchor
                                                          anchorOverride:anchor_override];
        }
    });
}

static void stack_selector_dispatch_remove(uint64_t selector_id)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[stack_selector_controller sharedController] removeSelector:selector_id];
    });
}

void stack_selector_destroy_node(struct window_node *node)
{
    if (!node || !node->stack_selector_id) return;

    uint64_t selector_id = node->stack_selector_id;
    node->stack_selector_id = 0;
    stack_selector_dispatch_remove(selector_id);
}

static void stack_selector_update_node_with_active_window_id(struct window_node *node, uint32_t active_window_id)
{
    if (!node) return;

    if (!g_stack_selector_enabled ||
        node->left ||
        node->right ||
        node->window_count <= 1 ||
        mission_control_is_active()) {
        stack_selector_destroy_node(node);
        return;
    }

    struct window *first_window = window_manager_find_window(&g_window_manager, node->window_list[0]);
    uint64_t sid = first_window ? window_space(first_window->id) : 0;
    if (!sid || !space_is_visible(sid)) {
        stack_selector_destroy_node(node);
        return;
    }

    struct area area = node->zoom ? node->zoom->area : node->area;
    enum stack_selector_anchor anchor = node->stack_selector_anchor_override
                                      ? node->stack_selector_anchor
                                      : g_stack_selector_default_anchor;
    bool horizontal = stack_selector_anchor_is_horizontal(anchor);
    CGFloat available_extent = horizontal ? area.w : area.h;
    CGFloat cross_extent = horizontal ? area.h : area.w;
    CGFloat item_extent = floor(MIN(STACK_SELECTOR_ROW_HEIGHT, available_extent / node->window_count));
    if (cross_extent < STACK_SELECTOR_WIDTH || item_extent < STACK_SELECTOR_MIN_ROW_HEIGHT) {
        stack_selector_destroy_node(node);
        return;
    }

    if (!node->stack_selector_id) {
        node->stack_selector_id = g_stack_selector_next_id++;
    }

    NSMutableArray *window_ids = [NSMutableArray arrayWithCapacity:node->window_count];
    NSMutableArray *pids = [NSMutableArray arrayWithCapacity:node->window_count];
    for (int i = 0; i < node->window_count; ++i) {
        uint32_t window_id = node->window_list[i];
        struct window *window = window_manager_find_window(&g_window_manager, window_id);
        [window_ids addObject:[NSNumber numberWithUnsignedInt:window_id]];
        [pids addObject:[NSNumber numberWithInt:window ? window->application->pid : 0]];
    }

    CGFloat width = horizontal ? item_extent * node->window_count : STACK_SELECTOR_WIDTH;
    CGFloat height = horizontal ? STACK_SELECTOR_WIDTH : item_extent * node->window_count;
    CGFloat cg_x;
    CGFloat cg_y;

    switch (anchor) {
    case STACK_SELECTOR_ANCHOR_VERTICAL_TOP_LEFT:
        cg_x = area.x;
        cg_y = area.y;
        break;
    case STACK_SELECTOR_ANCHOR_VERTICAL_CENTER_LEFT:
        cg_x = area.x;
        cg_y = area.y + (area.h - height) / 2.0f;
        break;
    case STACK_SELECTOR_ANCHOR_VERTICAL_BOTTOM_LEFT:
        cg_x = area.x;
        cg_y = area.y + area.h - height;
        break;
    case STACK_SELECTOR_ANCHOR_VERTICAL_TOP_RIGHT:
        cg_x = area.x + area.w - width;
        cg_y = area.y;
        break;
    case STACK_SELECTOR_ANCHOR_VERTICAL_CENTER_RIGHT:
        cg_x = area.x + area.w - width;
        cg_y = area.y + (area.h - height) / 2.0f;
        break;
    case STACK_SELECTOR_ANCHOR_VERTICAL_BOTTOM_RIGHT:
        cg_x = area.x + area.w - width;
        cg_y = area.y + area.h - height;
        break;
    case STACK_SELECTOR_ANCHOR_HORIZONTAL_LEFT_TOP:
        cg_x = area.x;
        cg_y = area.y;
        break;
    case STACK_SELECTOR_ANCHOR_HORIZONTAL_CENTER_TOP:
        cg_x = area.x + (area.w - width) / 2.0f;
        cg_y = area.y;
        break;
    case STACK_SELECTOR_ANCHOR_HORIZONTAL_RIGHT_TOP:
        cg_x = area.x + area.w - width;
        cg_y = area.y;
        break;
    case STACK_SELECTOR_ANCHOR_HORIZONTAL_LEFT_BOTTOM:
        cg_x = area.x;
        cg_y = area.y + area.h - height;
        break;
    case STACK_SELECTOR_ANCHOR_HORIZONTAL_CENTER_BOTTOM:
        cg_x = area.x + (area.w - width) / 2.0f;
        cg_y = area.y + area.h - height;
        break;
    case STACK_SELECTOR_ANCHOR_HORIZONTAL_RIGHT_BOTTOM:
        cg_x = area.x + area.w - width;
        cg_y = area.y + area.h - height;
        break;
    case STACK_SELECTOR_ANCHOR_COUNT:
        return;
    }

    CGFloat main_display_height = CGDisplayBounds(CGMainDisplayID()).size.height;
    CGRect frame = CGRectMake(cg_x,
                              main_display_height - cg_y - height,
                              width,
                              height);
    stack_selector_dispatch_update(node->stack_selector_id,
                                   frame,
                                   window_ids,
                                   pids,
                                   active_window_id,
                                   anchor,
                                   node->stack_selector_anchor_override);
}

void stack_selector_update_node(struct window_node *node)
{
    uint32_t active_window_id = node ? node->window_order[0] : 0;
    if (node && window_node_contains_window(node, g_window_manager.focused_window_id)) {
        active_window_id = g_window_manager.focused_window_id;
    }
    stack_selector_update_node_with_active_window_id(node, active_window_id);
}

void stack_selector_update_node_with_active_window(struct window_node *node, uint32_t window_id)
{
    if (!node || !window_node_contains_window(node, window_id)) {
        stack_selector_update_node(node);
        return;
    }
    stack_selector_update_node_with_active_window_id(node, window_id);
}

static void stack_selector_update_tree(struct window_node *node)
{
    if (!node) return;

    if (node->left || node->right) {
        stack_selector_destroy_node(node);
        stack_selector_update_tree(node->left);
        stack_selector_update_tree(node->right);
    } else {
        stack_selector_update_node(node);
    }
}

void stack_selector_update_all(void)
{
    table_for (struct view *view, g_space_manager.view, {
        stack_selector_update_tree(view->root);
    })
}

void stack_selector_hide_all(void)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[stack_selector_controller sharedController] hideAll];
    });
}

void stack_selector_set_enabled(bool enabled)
{
    if (g_stack_selector_enabled == enabled) return;

    g_stack_selector_enabled = enabled;
    stack_selector_update_all();
}

void stack_selector_set_default_anchor(enum stack_selector_anchor anchor)
{
    if (anchor < 0 || anchor >= STACK_SELECTOR_ANCHOR_COUNT || g_stack_selector_default_anchor == anchor) return;

    g_stack_selector_default_anchor = anchor;
    stack_selector_update_all();
}
