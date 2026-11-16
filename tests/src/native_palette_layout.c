// Real AppKit geometry, not another copy of the count * rowHeight arithmetic.
// Use stock cells here: custom-row ownership is tracked separately as t-010.
@interface palette_layout_fixture : NSObject <NSTableViewDataSource, NSTableViewDelegate> {
@public
    NSPanel *panel;
    NSScrollView *scroll;
    NSTableView *table;
    NSInteger count;
}
- (void)resizeForCount:(NSInteger)rowCount availableHeight:(CGFloat)availableHeight;
- (void)flushLayout;
@end

@implementation palette_layout_fixture
- (instancetype)init
{
    self = [super init];
    if (self) {
        [NSApplication sharedApplication];
        [NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];

        CGFloat width = modal_style_panel_width();
        panel = [[NSPanel alloc] initWithContentRect:NSMakeRect(0, 0, width, 400)
                                          styleMask:NSWindowStyleMaskBorderless | NSWindowStyleMaskNonactivatingPanel
                                            backing:NSBackingStoreBuffered
                                              defer:NO];
        panel.releasedWhenClosed = NO;

        NSView *root = [[[NSView alloc] initWithFrame:NSMakeRect(0, 0, width, 400)] autorelease];
        root.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        if (@available(macOS 27.0, *)) {
            NSGlassEffectView *glass = [[[NSGlassEffectView alloc] initWithFrame:root.bounds] autorelease];
            glass.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
            glass.contentView = root;
            panel.contentView = glass;
        } else {
            panel.contentView = root;
        }
        NSView *list = [[[NSView alloc] initWithFrame:root.bounds] autorelease];
        list.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        [root addSubview:list];

        // Start with the old large document/viewport, then resize as the palette
        // does. This catches padding that appears only after AppKit lays out.
        scroll = [[NSScrollView alloc] initWithFrame:NSMakeRect(8, 42, 634, 268)];
        scroll.drawsBackground = NO;
        scroll.hasVerticalScroller = YES;
        scroll.autohidesScrollers = YES;
        scroll.scrollerStyle = NSScrollerStyleOverlay;
        scroll.borderType = NSNoBorder;
        table = [[NSTableView alloc] initWithFrame:scroll.bounds];
        NSTableColumn *column = [[[NSTableColumn alloc] initWithIdentifier:@"action"] autorelease];
        column.width = width - 6.0f;
        [table addTableColumn:column];
        native_palette_configure_table(table);
        table.dataSource = self;
        table.delegate = self;
        scroll.documentView = table;
        [list addSubview:scroll];
    }
    return self;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return count;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)column row:(NSInteger)row
{
    return [NSTextField labelWithString:row ? @"zig-pcie" : @"web"];
}

- (void)flushLayout
{
    [panel.contentView layoutSubtreeIfNeeded];
    [table layoutSubtreeIfNeeded];
    // Allow AppKit's deferred layout to run as it does after showing a panel.
    // No panel is ordered onscreen and no daemon/IPC code runs in this fixture.
    CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.01, false);
    [panel.contentView layoutSubtreeIfNeeded];
}

- (void)resizeForCount:(NSInteger)rowCount availableHeight:(CGFloat)availableHeight
{
    count = rowCount;
    native_palette_configure_table(table);
    [table reloadData];
    CGFloat chrome = modal_style_current() == MODAL_STYLE_COMPACT ? 94.0f : 100.0f;
    CGFloat height = modal_style_list_height((size_t)count, chrome, availableHeight);
    CGFloat width = modal_style_panel_width();
    scroll.frame = NSMakeRect(6, 30, width - 12, height - chrome);
    table.frame = NSMakeRect(0, 0, scroll.contentView.bounds.size.width, count * table.rowHeight);
    [panel setFrame:NSMakeRect(0, 0, width, height) display:YES];
    [self flushLayout];
}

- (void)dealloc
{
    table.delegate = nil;
    table.dataSource = nil;
    scroll.documentView = nil;
    [table release];
    [scroll release];
    [panel close];
    [panel release];
    [super dealloc];
}
@end

TEST_FUNC(native_palette_short_lists_fit_after_layout, {
    @autoreleasepool {
        enum modal_style saved = modal_style_current();
        for (int style = MODAL_STYLE_DEFAULT; style <= MODAL_STYLE_COMPACT; ++style) {
            modal_style_set((enum modal_style)style);
            palette_layout_fixture *fixture = [[palette_layout_fixture alloc] init];
            for (NSInteger count = 1; count <= 10; ++count) {
                [fixture resizeForCount:count availableHeight:600];
                NSTableView *table = fixture->table;
                NSRect first = [table rectOfRow:0];
                NSRect last = [table rectOfRow:count - 1];
                TEST_CHECK(table.effectiveStyle == NSTableViewStylePlain, true);
                TEST_CHECK(NSMinY(first) == 0, true);
                TEST_CHECK(NSMaxY(last) == count * table.rowHeight, true);
                TEST_CHECK(NSHeight(table.visibleRect) == count * table.rowHeight, true);
                TEST_CHECK(NSContainsRect(table.visibleRect, first), true);
                TEST_CHECK(NSContainsRect(table.visibleRect, last), true);
            }
            [fixture release];
        }
        modal_style_set(saved);
    }
})

TEST_FUNC(native_palette_inset_negative_control, {
    @autoreleasepool {
        enum modal_style saved = modal_style_current();
        modal_style_set(MODAL_STYLE_DEFAULT);
        palette_layout_fixture *fixture = [[palette_layout_fixture alloc] init];
        [fixture resizeForCount:2 availableHeight:600];

        // The effective style seen in the live screenshot: zero scroll insets
        // and a 60pt document still leave the second row outside the viewport.
        fixture->table.style = NSTableViewStyleInset;
        fixture->scroll.automaticallyAdjustsContentInsets = NO;
        fixture->scroll.contentInsets = NSEdgeInsetsZero;
        fixture->table.frame = NSMakeRect(0, 0, 380, 60);
        [fixture flushLayout];
        NSRect clipped = [fixture->table rectOfRow:1];
        TEST_CHECK(NSMinY([fixture->table rectOfRow:0]) > 0, true);
        TEST_CHECK(NSContainsRect(fixture->table.visibleRect, clipped), false);

        // Production configuration removes the implicit padding, not by
        // inflating the panel. Both rows now fit in the same 60pt viewport.
        [fixture resizeForCount:2 availableHeight:600];
        NSRect last = [fixture->table rectOfRow:1];
        TEST_CHECK(NSMaxY(last) == 60, true);
        TEST_CHECK(NSHeight(fixture->table.visibleRect) == 60, true);
        TEST_CHECK(NSContainsRect(fixture->table.visibleRect, last), true);
        [fixture release];
        modal_style_set(saved);
    }
})

TEST_FUNC(native_palette_capped_lists_scroll_after_layout, {
    @autoreleasepool {
        enum modal_style saved = modal_style_current();
        for (int style = MODAL_STYLE_DEFAULT; style <= MODAL_STYLE_COMPACT; ++style) {
            modal_style_set((enum modal_style)style);
            palette_layout_fixture *fixture = [[palette_layout_fixture alloc] init];
            for (CGFloat available = 300; available <= 600; available += 300) {
                [fixture resizeForCount:100 availableHeight:available];
                // Resizing preserves the prior scroll position. Start each
                // cap case at row zero before testing that the end is hidden.
                [fixture->table scrollRectToVisible:[fixture->table rectOfRow:0]];
                [fixture flushLayout];
                NSRect last = [fixture->table rectOfRow:99];
                TEST_CHECK(NSHeight(fixture->panel.frame) <= 420, true);
                TEST_CHECK(NSHeight(fixture->panel.frame) <= available - 32, true);
                TEST_CHECK(NSContainsRect(fixture->table.visibleRect, last), false);
                [fixture->table scrollRectToVisible:last];
                [fixture flushLayout];
                TEST_CHECK(NSContainsRect(fixture->table.visibleRect, last), true);
            }
            [fixture release];
        }
        modal_style_set(saved);
    }
})

TEST_FUNC(native_palette_shrinks_back_to_two_rows, {
    @autoreleasepool {
        enum modal_style saved = modal_style_current();
        for (int style = MODAL_STYLE_DEFAULT; style <= MODAL_STYLE_COMPACT; ++style) {
            modal_style_set((enum modal_style)style);
            palette_layout_fixture *fixture = [[palette_layout_fixture alloc] init];
            [fixture resizeForCount:100 availableHeight:600];
            [fixture->table scrollRectToVisible:[fixture->table rectOfRow:99]];
            [fixture flushLayout];
            [fixture resizeForCount:2 availableHeight:600];
            CGFloat exactHeight = 2 * modal_style_row_height();
            TEST_CHECK(NSMinY(fixture->table.visibleRect) == 0, true);
            TEST_CHECK(NSHeight(fixture->table.visibleRect) == exactHeight, true);
            TEST_CHECK(NSContainsRect(fixture->table.visibleRect, [fixture->table rectOfRow:0]), true);
            TEST_CHECK(NSContainsRect(fixture->table.visibleRect, [fixture->table rectOfRow:1]), true);
            [fixture release];
        }
        modal_style_set(saved);
    }
})
