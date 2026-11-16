void native_palette_configure_table(NSTableView *table)
{
    // Automatic resolves to Inset in this hierarchy, adding top padding even
    // with zero intercell spacing/contentInsets. Plain makes row bounds match
    // the content-sized viewport; do not compensate by enlarging the panel.
    table.style = NSTableViewStylePlain;
    table.headerView = nil;
    table.backgroundColor = NSColor.clearColor;
    table.rowHeight = modal_style_row_height();
    table.intercellSpacing = NSMakeSize(0, 0);
    table.columnAutoresizingStyle = NSTableViewUniformColumnAutoresizingStyle;
    table.selectionHighlightStyle = NSTableViewSelectionHighlightStyleNone;
}

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

@implementation native_palette_row_view
- (instancetype)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    if (self) {
        _iconView = [[NSImageView alloc] initWithFrame:NSZeroRect];
        _iconView.imageScaling = NSImageScaleProportionallyDown;
        [self addSubview:_iconView];

        _titleField = [NSTextField labelWithString:@""];
        _titleField.font = [NSFont systemFontOfSize:13.0f weight:NSFontWeightRegular];
        _titleField.lineBreakMode = NSLineBreakByTruncatingTail;
        [self addSubview:_titleField];

        _contextField = [NSTextField labelWithString:@""];
        _contextField.font = [NSFont systemFontOfSize:11.0f weight:NSFontWeightMedium];
        _contextField.textColor = NSColor.secondaryLabelColor;
        _contextField.alignment = NSTextAlignmentRight;
        _contextField.lineBreakMode = NSLineBreakByTruncatingHead;
        [self addSubview:_contextField];
    }
    return self;
}

- (void)dealloc
{
    [_iconView release];
    [_titleField release];
    [_contextField release];
    [super dealloc];
}

// Generic action categories repeat across every row and add no signal; keep
// contextual categories (app name, Current, New Space) as a trailing token.
- (NSString *)contextForItem:(native_palette_item *)item
{
    NSString *category = item.category;
    if (!category.length) return nil;
    if (item.kind == NATIVE_PALETTE_ITEM_ACTION &&
        ([category isEqualToString:@"Window"] || [category isEqualToString:@"Space"] ||
         [category isEqualToString:@"Display"] || [category isEqualToString:@"Setting"])) {
        return nil;
    }
    return category;
}

- (void)updateWithItem:(native_palette_item *)item
{
    bool compact = modal_style_current() == MODAL_STYLE_COMPACT;
    CGFloat height = self.bounds.size.height;
    CGFloat width = self.bounds.size.width;
    CGFloat leading = compact ? 10.0f : 12.0f;
    CGFloat iconSize = compact ? 15.0f : 16.0f;
    CGFloat gap = compact ? 8.0f : 9.0f;
    CGFloat titleHeight = compact ? 15.0f : 17.0f;
    CGFloat contextHeight = compact ? 14.0f : 15.0f;

    if (item.iconImage) {
        _iconView.image = item.iconImage;
        _iconView.contentTintColor = nil;
    } else {
        NSImage *image = [NSImage imageWithSystemSymbolName:item.symbolName accessibilityDescription:nil];
        image = [image imageWithSymbolConfiguration:[NSImageSymbolConfiguration configurationWithPointSize:iconSize weight:NSFontWeightMedium]];
        _iconView.image = image;
        _iconView.contentTintColor = NSColor.controlAccentColor;
    }
    _iconView.frame = NSMakeRect(leading, (height - iconSize) / 2.0f, iconSize, iconSize);

    _titleField.font = [NSFont systemFontOfSize:compact ? 12.0f : 13.0f weight:NSFontWeightRegular];
    _titleField.stringValue = item.title ?: @"";

    CGFloat titleX = leading + iconSize + gap;
    NSString *context = [self contextForItem:item];
    if (context.length) {
        _contextField.stringValue = context;
        [_contextField sizeToFit];
        CGFloat contextWidth = MIN(floor(_contextField.frame.size.width), width * 0.42f);
        _contextField.frame = NSMakeRect(width - leading - contextWidth, (height - contextHeight) / 2.0f, contextWidth, contextHeight);
        _titleField.frame = NSMakeRect(titleX, (height - titleHeight) / 2.0f, MAX(0.0f, width - leading - titleX - contextWidth - gap), titleHeight);
    } else {
        _contextField.stringValue = @"";
        _titleField.frame = NSMakeRect(titleX, (height - titleHeight) / 2.0f, MAX(0.0f, width - leading - titleX), titleHeight);
    }

    NSString *tooltip = nil;
    if (item.detail.length && item.category.length) {
        tooltip = [NSString stringWithFormat:@"%@ — %@", item.detail, item.category];
    } else if (item.detail.length) {
        tooltip = item.detail;
    } else if (item.category.length) {
        tooltip = item.category;
    }
    self.toolTip = tooltip;
}
@end

@implementation native_palette_rename_view
@synthesize nameField = _nameField;
@synthesize saveButton = _saveButton;
@synthesize cancelButton = _cancelButton;
@synthesize errorScroll = _errorScroll;

- (instancetype)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // View ivars are borrowed from the owning subview tree. Do not manually
        // release autoreleased labels during teardown (see deferred t-010).
        self.accessibilityLabel = @"Rename workspace";

        _nameField = [[[NSTextField alloc] initWithFrame:NSZeroRect] autorelease];
        _nameField.controlSize = NSControlSizeSmall;
        _nameField.font = [NSFont systemFontOfSize:13.0f];
        _nameField.cell.usesSingleLineMode = YES;
        _nameField.cell.scrollable = YES;
        _nameField.placeholderString = @"Name (blank clears)";
        _nameField.focusRingType = NSFocusRingTypeNone;
        _nameField.wantsLayer = YES;
        _nameField.layer.cornerRadius = 4.0f;
        _nameField.layer.borderWidth = 1.0f;
        _nameField.accessibilityLabel = @"Workspace label";
        _nameField.toolTip = @"Leave blank to remove the label.";
        [self addSubview:_nameField];

        _saveButton = [NSButton buttonWithTitle:@"Rename" target:nil action:NULL];
        _saveButton.controlSize = NSControlSizeSmall;
        _saveButton.font = [NSFont systemFontOfSize:11.0f];
        _saveButton.bezelStyle = NSBezelStyleRounded;
        _saveButton.keyEquivalent = @"\r";
        [self addSubview:_saveButton];

        _cancelButton = [NSButton buttonWithTitle:@"Cancel" target:nil action:NULL];
        _cancelButton.controlSize = NSControlSizeSmall;
        _cancelButton.font = [NSFont systemFontOfSize:11.0f];
        _cancelButton.bezelStyle = NSBezelStyleRounded;
        _cancelButton.keyEquivalent = @"\x1b";
        _cancelButton.toolTip = @"Cancel (Escape)";
        [self addSubview:_cancelButton];

        _errorScroll = [[[NSScrollView alloc] initWithFrame:NSZeroRect] autorelease];
        _errorScroll.drawsBackground = NO;
        _errorScroll.borderType = NSNoBorder;
        _errorScroll.hasVerticalScroller = YES;
        _errorScroll.autohidesScrollers = YES;
        _errorScroll.scrollerStyle = NSScrollerStyleOverlay;
        _errorScroll.automaticallyAdjustsContentInsets = NO;
        _errorScroll.contentInsets = NSEdgeInsetsZero;
        _errorField = [NSTextField labelWithString:@""];
        _errorField.font = [NSFont systemFontOfSize:11.0f];
        _errorField.textColor = NSColor.systemRedColor;
        _errorField.selectable = YES;
        _errorField.maximumNumberOfLines = 0;
        _errorField.lineBreakMode = NSLineBreakByWordWrapping;
        _errorField.cell.wraps = YES;
        _errorField.cell.scrollable = NO;
        _errorScroll.documentView = _errorField;
        [self addSubview:_errorScroll];
        _errorScroll.hidden = YES;
    }
    return self;
}

- (void)setEditingDelegate:(id<NSTextFieldDelegate>)delegate
{
    _nameField.delegate = delegate;
    _errorField.delegate = delegate;
}

- (NSString *)errorMessage
{
    return _errorField.stringValue;
}

- (void)setErrorMessage:(NSString *)message
{
    _errorField.stringValue = message ?: @"";
    _errorField.toolTip = message.length ? message : nil;
    self.needsLayout = YES;
}

- (NSSize)configureForStyle:(enum modal_style)style availableHeight:(CGFloat)height
{
    struct modal_rename_layout base = modal_style_rename_layout_for(style, 0, height);
    CGFloat width = base.error.size.width;
    _errorField.preferredMaxLayoutWidth = width;
    _errorHeight = self.errorMessage.length
                 ? ceil([_errorField.cell cellSizeForBounds:NSMakeRect(0, 0, width, CGFLOAT_MAX)].height) : 0;
    _geometry = modal_style_rename_layout_for(style, _errorHeight, height);
    self.needsLayout = YES;
    return NSSizeFromCGSize(_geometry.size);
}

- (void)updateFocus
{
    _nameField.layer.borderColor = (_nameField.currentEditor ? NSColor.controlAccentColor : NSColor.separatorColor).CGColor;
}

- (void)layout
{
    [super layout];
    _nameField.frame = NSRectFromCGRect(_geometry.input);
    _saveButton.frame = NSRectFromCGRect(_geometry.save);
    _cancelButton.frame = NSRectFromCGRect(_geometry.cancel);
    _errorScroll.hidden = !self.errorMessage.length;
    _errorScroll.frame = NSRectFromCGRect(_geometry.error);
    _errorField.frame = NSMakeRect(0, 0, _geometry.error.size.width, MAX(1.0f, _errorHeight));
    CGFloat top = _errorField.isFlipped ? 0 : MAX(0, _errorHeight - _errorScroll.contentView.bounds.size.height);
    [_errorScroll.contentView scrollToPoint:NSMakePoint(0, top)];
    [_errorScroll reflectScrolledClipView:_errorScroll.contentView];
    [self updateFocus];
}
@end
