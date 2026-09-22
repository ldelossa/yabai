@implementation native_palette_item
@synthesize title = _title;
@synthesize detail = _detail;
@synthesize category = _category;
@synthesize symbolName = _symbolName;
@synthesize badge = _badge;
@synthesize iconImage = _iconImage;
@synthesize badgeStyle = _badgeStyle;
@synthesize kind = _kind;
@synthesize representedPointer = _representedPointer;
@synthesize representedValue = _representedValue;

+ (instancetype)itemWithTitle:(NSString *)title
                       detail:(NSString *)detail
                     category:(NSString *)category
                   symbolName:(NSString *)symbolName
                         kind:(enum native_palette_item_kind)kind
{
    native_palette_item *item = [[[self alloc] init] autorelease];
    item.title = title;
    item.detail = detail;
    item.category = category;
    item.symbolName = symbolName;
    item.kind = kind;
    item.badgeStyle = NATIVE_PALETTE_BADGE_NONE;
    return item;
}

- (void)dealloc
{
    [_title release];
    [_detail release];
    [_category release];
    [_symbolName release];
    [_badge release];
    [_iconImage release];
    [super dealloc];
}
@end

@implementation native_palette_row
@synthesize row = _row;

- (instancetype)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    if (self) {
        _highlightView = [[NSView alloc] initWithFrame:NSZeroRect];
        _highlightView.wantsLayer = YES;
        _highlightView.layer.cornerRadius = 9.0f;
        _highlightView.layer.masksToBounds = YES;
        _highlightView.hidden = YES;
        [self addSubview:_highlightView positioned:NSWindowBelow relativeTo:nil];
    }
    return self;
}

- (void)dealloc
{
    [_highlightView release];
    [super dealloc];
}

- (void)layout
{
    [super layout];
    _highlightView.frame = NSInsetRect(self.bounds, 0.0f, 2.0f);
}

- (void)setVisualState:(enum native_palette_row_visual_state)visualState
{
    _visualState = visualState;
    if (_visualState == NATIVE_PALETTE_ROW_NONE) {
        _highlightView.hidden = YES;
        return;
    }

    bool selected = _visualState == NATIVE_PALETTE_ROW_SELECTED;
    NSColor *fill = selected
                  ? [[NSColor controlAccentColor] colorWithAlphaComponent:0.30f]
                  : [[NSColor labelColor] colorWithAlphaComponent:0.10f];

    _highlightView.layer.backgroundColor = fill.CGColor;
    _highlightView.layer.borderWidth = selected ? 1.0f : 0.0f;
    _highlightView.layer.borderColor = selected
                                    ? [[NSColor controlAccentColor] colorWithAlphaComponent:0.55f].CGColor
                                    : NSColor.clearColor.CGColor;
    _highlightView.hidden = NO;
}
@end

@interface native_palette_badge_cell : NSTextFieldCell
@end

@implementation native_palette_badge_cell
- (NSRect)drawingRectForBounds:(NSRect)rect
{
    NSRect drawing_rect = [super drawingRectForBounds:rect];
    NSSize text_size = [self cellSizeForBounds:rect];
    CGFloat height_delta = drawing_rect.size.height - text_size.height;
    if (height_delta > 0.0f) {
        drawing_rect.origin.y += floor(height_delta / 2.0f);
        drawing_rect.size.height -= height_delta;
    }
    return drawing_rect;
}
@end

@implementation native_palette_row_view
- (instancetype)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    if (self) {
        _iconView = [[NSImageView alloc] initWithFrame:NSMakeRect(10, 7, 30, 30)];
        _iconView.imageScaling = NSImageScaleProportionallyDown;
        [self addSubview:_iconView];

        _titleField = [NSTextField labelWithString:@""];
        _titleField.frame = NSMakeRect(52, 23, 350, 18);
        _titleField.font = [NSFont systemFontOfSize:14.0f weight:NSFontWeightSemibold];
        _titleField.lineBreakMode = NSLineBreakByTruncatingTail;
        [self addSubview:_titleField];

        _detailField = [NSTextField labelWithString:@""];
        _detailField.frame = NSMakeRect(52, 5, 400, 17);
        _detailField.font = [NSFont monospacedSystemFontOfSize:11.0f weight:NSFontWeightRegular];
        _detailField.textColor = NSColor.secondaryLabelColor;
        _detailField.lineBreakMode = NSLineBreakByTruncatingTail;
        [self addSubview:_detailField];

        _categoryField = [NSTextField labelWithString:@""];
        _categoryField.font = [NSFont systemFontOfSize:10.0f weight:NSFontWeightMedium];
        _categoryField.textColor = NSColor.tertiaryLabelColor;
        _categoryField.alignment = NSTextAlignmentRight;
        [self addSubview:_categoryField];

        _badgeField = [NSTextField labelWithString:@""];
        _badgeField.cell = [[[native_palette_badge_cell alloc] initTextCell:@""] autorelease];
        _badgeField.wantsLayer = YES;
        _badgeField.layer.cornerRadius = 6.0f;
        _badgeField.layer.masksToBounds = YES;
        _badgeField.font = [NSFont systemFontOfSize:10.5f weight:NSFontWeightSemibold];
        _badgeField.alignment = NSTextAlignmentCenter;
        _badgeField.hidden = YES;
        [self addSubview:_badgeField];
    }
    return self;
}

- (void)dealloc
{
    [_iconView release];
    [_titleField release];
    [_detailField release];
    [_categoryField release];
    [_badgeField release];
    [super dealloc];
}

- (NSColor *)badgeColorForStyle:(enum native_palette_badge_style)style
{
    switch (style) {
    case NATIVE_PALETTE_BADGE_SELECTOR: return NSColor.systemOrangeColor;
    case NATIVE_PALETTE_BADGE_ENUM: return NSColor.systemBlueColor;
    case NATIVE_PALETTE_BADGE_NATIVE: return NSColor.systemGreenColor;
    case NATIVE_PALETTE_BADGE_TEXT:
    default: return NSColor.secondaryLabelColor;
    }
}

- (void)updateWithItem:(native_palette_item *)item
{
    if (item.iconImage) {
        _iconView.image = item.iconImage;
        _iconView.contentTintColor = nil;
    } else {
        NSImage *image = [NSImage imageWithSystemSymbolName:item.symbolName accessibilityDescription:nil];
        image = [image imageWithSymbolConfiguration:[NSImageSymbolConfiguration configurationWithPointSize:16.0f weight:NSFontWeightMedium]];
        _iconView.image = image;
        _iconView.contentTintColor = NSColor.controlAccentColor;
    }

    _titleField.stringValue = item.title ?: @"";
    _detailField.stringValue = item.detail ?: @"";

    CGFloat rightEdge = self.bounds.size.width;
    NSString *badge = item.badge;
    if (badge.length) {
        _badgeField.stringValue = badge;
        NSColor *tint = [self badgeColorForStyle:item.badgeStyle];
        _badgeField.textColor = tint;
        _badgeField.layer.backgroundColor = [tint colorWithAlphaComponent:0.12f].CGColor;
        _badgeField.layer.borderColor = [tint colorWithAlphaComponent:0.45f].CGColor;
        _badgeField.layer.borderWidth = 1.0f;
        [_badgeField sizeToFit];
        CGFloat badgeWidth = _badgeField.frame.size.width + 14.0f;
        _badgeField.frame = NSMakeRect(rightEdge - badgeWidth - 12.0f, 13.0f, badgeWidth, 20.0f);
        _badgeField.hidden = NO;
        rightEdge -= badgeWidth + 20.0f;
    } else {
        _badgeField.hidden = YES;
    }

    if (item.category.length) {
        _categoryField.stringValue = item.category.uppercaseString;
        [_categoryField sizeToFit];
        CGFloat categoryWidth = _categoryField.frame.size.width;
        _categoryField.frame = NSMakeRect(rightEdge - categoryWidth, 14.0f, categoryWidth, 17.0f);
    } else {
        _categoryField.stringValue = @"";
    }
}
@end
