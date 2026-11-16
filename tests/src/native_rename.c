@interface rename_view_fixture : NSObject {
@public
    NSPanel *panel;
    native_palette_rename_view *view;
    NSUInteger saves, cancels;
    NSString *lastSavedValue;
}
- (void)applyStyle:(enum modal_style)style availableHeight:(CGFloat)height;
- (void)save:(id)sender;
- (void)cancel:(id)sender;
@end

@implementation rename_view_fixture
- (instancetype)init
{
    self = [super init];
    if (self) {
        [NSApplication sharedApplication];
        [NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
        panel = [[NSPanel alloc] initWithContentRect:NSMakeRect(0, 0, 392, 400)
                                          styleMask:NSWindowStyleMaskBorderless | NSWindowStyleMaskNonactivatingPanel
                                            backing:NSBackingStoreBuffered defer:NO];
        panel.releasedWhenClosed = NO;
        NSView *root = [[[NSView alloc] initWithFrame:NSMakeRect(0, 0, 392, 400)] autorelease];
        root.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        if (@available(macOS 27.0, *)) {
            NSGlassEffectView *glass = [[[NSGlassEffectView alloc] initWithFrame:root.bounds] autorelease];
            glass.contentView = root;
            panel.contentView = glass;
        } else {
            panel.contentView = root;
        }
        view = [[native_palette_rename_view alloc] initWithFrame:root.bounds];
        view.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        view.saveButton.target = self;
        view.saveButton.action = @selector(save:);
        view.cancelButton.target = self;
        view.cancelButton.action = @selector(cancel:);
        [root addSubview:view];
    }
    return self;
}
- (void)applyStyle:(enum modal_style)style availableHeight:(CGFloat)height
{
    NSSize size = [view configureForStyle:style availableHeight:height];
    [panel setFrame:NSMakeRect(0, 0, size.width, size.height) display:YES];
    [panel.contentView layoutSubtreeIfNeeded];
    view.frame = NSMakeRect(0, 0, size.width, size.height);
    [view layoutSubtreeIfNeeded];
    CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.01, false);
    [panel.contentView layoutSubtreeIfNeeded];
}
- (void)save:(id)sender
{
    ++saves;
    [lastSavedValue release];
    lastSavedValue = [view.nameField.stringValue copy];
}
- (void)cancel:(id)sender
{
    ++cancels;
}
- (void)dealloc
{
    view.saveButton.target = nil;
    view.cancelButton.target = nil;
    [view release];
    [panel close];
    [panel release];
    [lastSavedValue release];
    [super dealloc];
}
@end

// Exercise the actual controller's field/keyboard routing without constructing
// its table or posting an action to the real window-manager event loop.
@interface rename_key_probe : command_palette_controller {
@public
    int saveCalls, cancelCalls;
    NSString *saved;
}
- (NSTextField *)input;
- (NSTextField *)errorInput;
@end
@implementation rename_key_probe
- (instancetype)init
{
    self = [super init];
    if (self) {
        _state = COMMAND_PALETTE_VIEW_INPUT;
        _pendingAction = command_palette_find_action("space.relabel");
        _renameView = [[native_palette_rename_view alloc] initWithFrame:NSZeroRect];
        [_renameView setEditingDelegate:self];
    }
    return self;
}
- (NSTextField *)input { return _renameView.nameField; }
- (NSTextField *)errorInput { return (NSTextField *)_renameView.errorScroll.documentView; }
- (void)runPendingAction:(id)sender
{
    ++saveCalls;
    [saved release];
    saved = [_renameView.nameField.stringValue copy];
}
- (void)cancelPalette:(id)sender { ++cancelCalls; }
- (void)dealloc
{
    [_renameView setEditingDelegate:nil];
    [_renameView release];
    _renameView = nil;
    [saved release];
    [super dealloc];
}
@end

TEST_FUNC(native_rename_controller_routes_keys, {
    @autoreleasepool {
        rename_key_probe *probe = [[rename_key_probe alloc] init];
        probe.input.stringValue = @"new-name";
        TEST_CHECK([probe control:probe.input textView:nil doCommandBySelector:@selector(insertNewline:)], true);
        TEST_CHECK(probe->saveCalls, 1);
        TEST_CHECK([probe->saved isEqualToString:@"new-name"], true);
        probe.input.stringValue = @"";
        TEST_CHECK([probe control:probe.input textView:nil doCommandBySelector:@selector(insertNewline:)], true);
        TEST_CHECK(probe->saveCalls, 2);
        TEST_CHECK([probe->saved isEqualToString:@""], true);
        TEST_CHECK([probe control:probe.input textView:nil doCommandBySelector:@selector(cancelOperation:)], true);
        TEST_CHECK(probe->cancelCalls, 1);
        NSTextField *errorField = [probe errorInput];
        TEST_CHECK(errorField.delegate == probe, true);
        TEST_CHECK([probe control:errorField textView:nil doCommandBySelector:@selector(cancelOperation:)], true);
        TEST_CHECK(probe->cancelCalls, 2);
        [probe release];
    }
})

TEST_FUNC(native_rename_inline_controls_fit, {
    @autoreleasepool {
        rename_view_fixture *fixture = [[rename_view_fixture alloc] init];
        NSString *name = @"long-workspace-name-that-remains-fully-editable";
        fixture->view.nameField.stringValue = name;
        for (int pass = 0; pass < 6; ++pass) {
            enum modal_style style = pass % 2 ? MODAL_STYLE_COMPACT : MODAL_STYLE_DEFAULT;
            [fixture applyStyle:style availableHeight:600];
            NSRect bounds = fixture->view.bounds;
            TEST_CHECK((int)NSWidth(bounds), style == MODAL_STYLE_COMPACT ? 288 : 320);
            TEST_CHECK((int)NSHeight(bounds), style == MODAL_STYLE_COMPACT ? 60 : 68);
            for (NSView *child in fixture->view.subviews) {
                if (!child.hidden) TEST_CHECK(NSContainsRect(bounds, child.frame), true);
            }
            NSRect textRect = [fixture->view.nameField.cell drawingRectForBounds:fixture->view.nameField.bounds];
            NSFont *font = fixture->view.nameField.font;
            TEST_CHECK(NSHeight(textRect) >= ceil(font.ascender - font.descender), true);
            TEST_CHECK([fixture->view.saveButton.title isEqualToString:@"Rename"], true);
            TEST_CHECK(NSIntersectsRect(fixture->view.nameField.frame, fixture->view.saveButton.frame), false);
            NSRect save = fixture->view.saveButton.frame;
            NSRect cancel = fixture->view.cancelButton.frame;
            TEST_CHECK(NSMinX(save) == NSMinX(cancel) && NSWidth(save) == NSWidth(cancel), true);
            TEST_CHECK(NSMinY(save) > NSMaxY(cancel), true);
            TEST_CHECK(NSMinX(save) > NSMaxX(fixture->view.nameField.frame), true);
            TEST_CHECK(NSMidY(fixture->view.nameField.frame) == (NSMidY(save) + NSMidY(cancel)) / 2, true);
            for (NSView *child in fixture->view.subviews) {
                if (![child isKindOfClass:[NSButton class]]) continue;
                NSButton *button = (NSButton *)child;
                NSRect title = [button.cell titleRectForBounds:button.bounds];
                TEST_CHECK(NSHeight(title) >= ceil(button.font.ascender - button.font.descender), true);
                CGFloat textWidth = [button.attributedTitle size].width;
                // AppKit fits this rect to the fractional natural text size.
                // Rounding up would reject a fully visible 42.04pt title in a
                // 42.5pt rect; the old compact 35pt rect must still fail.
                TEST_CHECK(NSWidth(title) + 0.01 >= textWidth, true);
            }
            TEST_CHECK([fixture->view.nameField.placeholderString containsString:@"blank clears"], true);
            TEST_CHECK([fixture->view.accessibilityLabel isEqualToString:@"Rename workspace"], true);
            TEST_CHECK(NSIntersectsRect(fixture->view.nameField.frame, fixture->view.cancelButton.frame), false);
            TEST_CHECK([fixture->view.nameField.stringValue isEqualToString:name], true);
            TEST_CHECK(fixture->view.errorScroll.hidden, true);
        }
        // Global palette dimensions and list geometry are not a rename setting.
        TEST_CHECK((int)modal_style_width_for(MODAL_STYLE_DEFAULT), 392);
        TEST_CHECK((int)modal_style_width_for(MODAL_STYLE_COMPACT), 320);
        [fixture release];
    }
})

TEST_FUNC(native_rename_errors_scroll_and_shrink, {
    @autoreleasepool {
        rename_view_fixture *fixture = [[rename_view_fixture alloc] init];
        NSString *message = [@"That label is unavailable. " stringByPaddingToLength:6000 withString:@"Detailed failure. Choose another name. " startingAtIndex:0];
        fixture->view.nameField.stringValue = @"keep-my-edit";
        for (int style = MODAL_STYLE_DEFAULT; style <= MODAL_STYLE_COMPACT; ++style) {
            for (CGFloat available = 180; available <= 600; available += 420) {
                fixture->view.errorMessage = message;
                [fixture applyStyle:(enum modal_style)style availableHeight:available];
                NSScrollView *scroll = fixture->view.errorScroll;
                NSTextField *document = (NSTextField *)scroll.documentView;
                TEST_CHECK(NSHeight(fixture->view.bounds) <= 420, true);
                TEST_CHECK(NSHeight(fixture->view.bounds) <= available - 32, true);
                TEST_CHECK(scroll.hidden, false);
                TEST_CHECK(NSHeight(document.bounds) > NSHeight(scroll.contentView.bounds), true);
                TEST_CHECK([document.stringValue isEqualToString:message], true);
                TEST_CHECK(document.isSelectable, true);
                TEST_CHECK(NSIntersectsRect(scroll.frame, fixture->view.nameField.frame), false);
                TEST_CHECK(NSIntersectsRect(scroll.frame, fixture->view.cancelButton.frame), false);
                for (NSView *child in fixture->view.subviews) {
                    if (!child.hidden) TEST_CHECK(NSContainsRect(fixture->view.bounds, child.frame), true);
                }
                if (document.isFlipped) {
                    TEST_CHECK(fabs(NSMinY(scroll.documentVisibleRect)) < 1, true);
                } else {
                    TEST_CHECK(fabs(NSMaxY(scroll.documentVisibleRect) - NSHeight(document.bounds)) < 1, true);
                }
                fixture->view.errorMessage = @"";
                [fixture applyStyle:(enum modal_style)style availableHeight:available];
                TEST_CHECK((int)NSHeight(fixture->view.bounds), style == MODAL_STYLE_COMPACT ? 60 : 68);
                TEST_CHECK(fixture->view.errorScroll.hidden, true);
                TEST_CHECK([fixture->view.nameField.stringValue isEqualToString:@"keep-my-edit"], true);
            }
        }
        [fixture release];
    }
})

TEST_FUNC(native_rename_actions_and_teardown, {
    for (int pass = 0; pass < 6; ++pass) {
        @autoreleasepool {
            rename_view_fixture *fixture = [[rename_view_fixture alloc] init];
            [fixture applyStyle:pass % 2 ? MODAL_STYLE_COMPACT : MODAL_STYLE_DEFAULT availableHeight:600];
            TEST_CHECK([fixture->view.saveButton.keyEquivalent isEqualToString:@"\r"], true);
            TEST_CHECK([fixture->view.cancelButton.keyEquivalent isEqualToString:@"\x1b"], true);
            fixture->view.nameField.stringValue = @"renamed";
            [fixture->view.saveButton performClick:nil];
            TEST_CHECK((int)fixture->saves, 1);
            TEST_CHECK([fixture->lastSavedValue isEqualToString:@"renamed"], true);
            fixture->view.nameField.stringValue = @"";
            [fixture->view.saveButton performClick:nil];
            TEST_CHECK((int)fixture->saves, 2);
            TEST_CHECK([fixture->lastSavedValue isEqualToString:@""], true);
            [fixture->view.cancelButton performClick:nil];
            TEST_CHECK((int)fixture->cancels, 1);
            [fixture release];
        }
    }
})
