@implementation native_palette_item
@synthesize title = _title;
@synthesize detail = _detail;
@synthesize category = _category;
@synthesize symbolName = _symbolName;
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
    return item;
}

- (void)dealloc
{
    [_title release];
    [_detail release];
    [_category release];
    [_symbolName release];
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

@implementation native_palette_row_view
- (instancetype)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    if (self) {
        _iconView = [[NSImageView alloc] initWithFrame:NSMakeRect(10, 7, 30, 30)];
        _iconView.imageScaling = NSImageScaleProportionallyDown;
        [self addSubview:_iconView];

        _titleField = [NSTextField labelWithString:@""];
        _titleField.frame = NSMakeRect(52, 23, 430, 18);
        _titleField.font = [NSFont systemFontOfSize:14.0f weight:NSFontWeightSemibold];
        _titleField.lineBreakMode = NSLineBreakByTruncatingTail;
        [self addSubview:_titleField];

        _detailField = [NSTextField labelWithString:@""];
        _detailField.frame = NSMakeRect(52, 5, 470, 17);
        _detailField.font = [NSFont monospacedSystemFontOfSize:11.0f weight:NSFontWeightRegular];
        _detailField.textColor = NSColor.secondaryLabelColor;
        _detailField.lineBreakMode = NSLineBreakByTruncatingTail;
        [self addSubview:_detailField];

        _categoryField = [NSTextField labelWithString:@""];
        _categoryField.frame = NSMakeRect(530, 14, 82, 17);
        _categoryField.font = [NSFont systemFontOfSize:10.0f weight:NSFontWeightMedium];
        _categoryField.textColor = NSColor.tertiaryLabelColor;
        _categoryField.alignment = NSTextAlignmentRight;
        [self addSubview:_categoryField];
    }
    return self;
}

- (void)dealloc
{
    [_iconView release];
    [super dealloc];
}

- (void)updateWithItem:(native_palette_item *)item
{
    NSImage *image = [NSImage imageWithSystemSymbolName:item.symbolName accessibilityDescription:nil];
    image = [image imageWithSymbolConfiguration:[NSImageSymbolConfiguration configurationWithPointSize:16.0f weight:NSFontWeightMedium]];
    _iconView.image = image;
    _iconView.contentTintColor = NSColor.controlAccentColor;
    _titleField.stringValue = item.title ?: @"";
    _detailField.stringValue = item.detail ?: @"";
    _categoryField.stringValue = item.category.uppercaseString ?: @"";
}
@end
