#define COMMAND_PALETTE_ACTION(identifier_, title_, category_, domain_, command_, syntax_, description_, argument_mode_, destructive_) \
    { identifier_, title_, category_, domain_, command_, syntax_, description_, argument_mode_, COMMAND_PALETTE_ACTION_IPC, COMMAND_PALETTE_NATIVE_NONE, destructive_ }

#define COMMAND_PALETTE_NATIVE_ACTION(identifier_, title_, category_, description_, native_action_) \
    { identifier_, title_, category_, NULL, NULL, NULL, description_, COMMAND_PALETTE_ARGUMENT_NONE, COMMAND_PALETTE_ACTION_NATIVE, native_action_, false }

const struct command_palette_action g_command_palette_actions[] =
{
    COMMAND_PALETTE_ACTION("display.focus", "Focus Display", "Display", DOMAIN_DISPLAY, COMMAND_DISPLAY_FOCUS, "DISPLAY_SEL", "Focus a display by selector, index, or label.", COMMAND_PALETTE_ARGUMENT_REQUIRED, false),
    COMMAND_PALETTE_ACTION("display.space", "Show Space on Display", "Display", DOMAIN_DISPLAY, COMMAND_DISPLAY_SPACE, "SPACE_SEL", "Show a space on the selected display without changing focus.", COMMAND_PALETTE_ARGUMENT_REQUIRED, false),
    COMMAND_PALETTE_ACTION("display.label", "Label Display", "Display", DOMAIN_DISPLAY, COMMAND_DISPLAY_LABEL, "LABEL", "Set a display label, or leave empty to clear it.", COMMAND_PALETTE_ARGUMENT_OPTIONAL, false),

    COMMAND_PALETTE_NATIVE_ACTION("space.choose", "Choose Space", "Space", "Search existing spaces or create and focus a labeled space.", COMMAND_PALETTE_NATIVE_SPACE_CHOOSE),
    COMMAND_PALETTE_NATIVE_ACTION("space.relabel", "Relabel Focused Space", "Space", "Change or clear the focused space label.", COMMAND_PALETTE_NATIVE_SPACE_RELABEL),
    COMMAND_PALETTE_NATIVE_ACTION("space.layout-cycle", "Cycle Space Layout", "Space", "Cycle the focused space through stack, BSP, and float layouts.", COMMAND_PALETTE_NATIVE_SPACE_LAYOUT_CYCLE),

    COMMAND_PALETTE_ACTION("space.focus", "Focus Space", "Space", DOMAIN_SPACE, COMMAND_SPACE_FOCUS, "SPACE_SEL", "Focus a space by selector, index, or label.", COMMAND_PALETTE_ARGUMENT_REQUIRED, false),
    COMMAND_PALETTE_ACTION("space.switch", "Switch Space", "Space", DOMAIN_SPACE, COMMAND_SPACE_SWITCH, "SPACE_SEL", "Substitute the focused space with another space.", COMMAND_PALETTE_ARGUMENT_REQUIRED, false),
    COMMAND_PALETTE_ACTION("space.create", "Create Space", "Space", DOMAIN_SPACE, COMMAND_SPACE_CREATE, NULL, "Create a space on the active display.", COMMAND_PALETTE_ARGUMENT_NONE, false),
    COMMAND_PALETTE_ACTION("space.destroy", "Destroy Space", "Space", DOMAIN_SPACE, COMMAND_SPACE_DESTROY, NULL, "Destroy the focused space.", COMMAND_PALETTE_ARGUMENT_NONE, true),
    COMMAND_PALETTE_ACTION("space.move", "Move Space", "Space", DOMAIN_SPACE, COMMAND_SPACE_MOVE, "SPACE_SEL", "Move the focused space to another position.", COMMAND_PALETTE_ARGUMENT_REQUIRED, false),
    COMMAND_PALETTE_ACTION("space.swap", "Swap Space", "Space", DOMAIN_SPACE, COMMAND_SPACE_SWAP, "SPACE_SEL", "Swap the focused space with another space.", COMMAND_PALETTE_ARGUMENT_REQUIRED, false),
    COMMAND_PALETTE_ACTION("space.display", "Move Space to Display", "Space", DOMAIN_SPACE, COMMAND_SPACE_DISPLAY, "DISPLAY_SEL", "Move the focused space to another display.", COMMAND_PALETTE_ARGUMENT_REQUIRED, false),
    COMMAND_PALETTE_ACTION("space.equalize", "Equalize Space", "Space", DOMAIN_SPACE, COMMAND_SPACE_EQUALIZE, NULL, "Reset all split ratios on the focused space.", COMMAND_PALETTE_ARGUMENT_NONE, false),
    COMMAND_PALETTE_ACTION("space.balance", "Balance Space", "Space", DOMAIN_SPACE, COMMAND_SPACE_BALANCE, NULL, "Balance all windows on the focused space.", COMMAND_PALETTE_ARGUMENT_NONE, false),
    COMMAND_PALETTE_ACTION("space.mirror", "Mirror Space", "Space", DOMAIN_SPACE, COMMAND_SPACE_MIRROR, "x-axis | y-axis", "Mirror the focused space along an axis.", COMMAND_PALETTE_ARGUMENT_REQUIRED, false),
    COMMAND_PALETTE_ACTION("space.rotate", "Rotate Space", "Space", DOMAIN_SPACE, COMMAND_SPACE_ROTATE, "90 | 180 | 270", "Rotate the focused space.", COMMAND_PALETTE_ARGUMENT_REQUIRED, false),
    COMMAND_PALETTE_ACTION("space.padding", "Set Space Padding", "Space", DOMAIN_SPACE, COMMAND_SPACE_PADDING, "abs|rel:top:bottom:left:right", "Set absolute or relative padding for the focused space.", COMMAND_PALETTE_ARGUMENT_REQUIRED, false),
    COMMAND_PALETTE_ACTION("space.gap", "Set Space Gap", "Space", DOMAIN_SPACE, COMMAND_SPACE_GAP, "abs|rel:gap", "Set the absolute or relative gap for the focused space.", COMMAND_PALETTE_ARGUMENT_REQUIRED, false),
    COMMAND_PALETTE_ACTION("space.toggle", "Toggle Space Setting", "Space", DOMAIN_SPACE, COMMAND_SPACE_TOGGLE, "padding | gap | mission-control | show-desktop", "Toggle a setting on the focused space.", COMMAND_PALETTE_ARGUMENT_REQUIRED, false),
    COMMAND_PALETTE_ACTION("space.layout", "Set Space Layout", "Space", DOMAIN_SPACE, COMMAND_SPACE_LAYOUT, "bsp | stack | float", "Set the focused space layout.", COMMAND_PALETTE_ARGUMENT_REQUIRED, false),
    COMMAND_PALETTE_ACTION("space.label", "Label Space", "Space", DOMAIN_SPACE, COMMAND_SPACE_LABEL, "LABEL", "Set a space label, or leave empty to clear it.", COMMAND_PALETTE_ARGUMENT_OPTIONAL, false),

    COMMAND_PALETTE_ACTION("window.focus", "Focus Window", "Window", DOMAIN_WINDOW, COMMAND_WINDOW_FOCUS, "WINDOW_SEL", "Focus a window by selector or id.", COMMAND_PALETTE_ARGUMENT_REQUIRED, false),
    COMMAND_PALETTE_ACTION("window.close", "Close Window", "Window", DOMAIN_WINDOW, COMMAND_WINDOW_CLOSE, NULL, "Close the focused window.", COMMAND_PALETTE_ARGUMENT_NONE, true),
    COMMAND_PALETTE_ACTION("window.minimize", "Minimize Window", "Window", DOMAIN_WINDOW, COMMAND_WINDOW_MINIMIZE, NULL, "Minimize the focused window.", COMMAND_PALETTE_ARGUMENT_NONE, false),
    COMMAND_PALETTE_ACTION("window.deminimize", "Restore Window", "Window", DOMAIN_WINDOW, COMMAND_WINDOW_DEMINIMIZE, "WINDOW_SEL", "Restore a minimized window.", COMMAND_PALETTE_ARGUMENT_REQUIRED, false),
    COMMAND_PALETTE_ACTION("window.display", "Move Window to Display", "Window", DOMAIN_WINDOW, COMMAND_WINDOW_DISPLAY, "DISPLAY_SEL", "Move the focused window to another display.", COMMAND_PALETTE_ARGUMENT_REQUIRED, false),
    COMMAND_PALETTE_ACTION("window.space", "Move Window to Space", "Window", DOMAIN_WINDOW, COMMAND_WINDOW_SPACE, "SPACE_SEL", "Move the focused window to another space.", COMMAND_PALETTE_ARGUMENT_REQUIRED, false),
    COMMAND_PALETTE_ACTION("window.swap", "Swap Window", "Window", DOMAIN_WINDOW, COMMAND_WINDOW_SWAP, "WINDOW_SEL", "Swap the focused window with another window.", COMMAND_PALETTE_ARGUMENT_REQUIRED, false),
    COMMAND_PALETTE_ACTION("window.warp", "Warp Window", "Window", DOMAIN_WINDOW, COMMAND_WINDOW_WARP, "WINDOW_SEL", "Warp the focused window onto another window.", COMMAND_PALETTE_ARGUMENT_REQUIRED, false),
    COMMAND_PALETTE_ACTION("window.stack", "Stack Window", "Window", DOMAIN_WINDOW, COMMAND_WINDOW_STACK, "WINDOW_SEL", "Stack another window onto the focused window.", COMMAND_PALETTE_ARGUMENT_REQUIRED, false),
    COMMAND_PALETTE_ACTION("window.insert", "Set Window Insertion", "Window", DOMAIN_WINDOW, COMMAND_WINDOW_INSERT, "north | east | south | west | stack", "Set the insertion direction for the focused window.", COMMAND_PALETTE_ARGUMENT_REQUIRED, false),
    COMMAND_PALETTE_ACTION("window.grid", "Apply Window Grid", "Window", DOMAIN_WINDOW, COMMAND_WINDOW_GRID, "rows:cols:x:y:w:h", "Apply a grid frame to the focused window.", COMMAND_PALETTE_ARGUMENT_REQUIRED, false),
    COMMAND_PALETTE_ACTION("window.move", "Move Window", "Window", DOMAIN_WINDOW, COMMAND_WINDOW_MOVE, "abs|rel:dx:dy", "Move the focused window.", COMMAND_PALETTE_ARGUMENT_REQUIRED, false),
    COMMAND_PALETTE_ACTION("window.resize", "Resize Window", "Window", DOMAIN_WINDOW, COMMAND_WINDOW_RESIZE, "handle:dx:dy", "Resize the focused window.", COMMAND_PALETTE_ARGUMENT_REQUIRED, false),
    COMMAND_PALETTE_ACTION("window.ratio", "Adjust Window Ratio", "Window", DOMAIN_WINDOW, COMMAND_WINDOW_RATIO, "abs|rel:ratio", "Adjust the split ratio for the focused window.", COMMAND_PALETTE_ARGUMENT_REQUIRED, false),
    COMMAND_PALETTE_ACTION("window.toggle", "Toggle Window Setting", "Window", DOMAIN_WINDOW, COMMAND_WINDOW_TOGGLE, "float | sticky | pip | shadow | split | zoom-parent | zoom-fullscreen | windowed-fullscreen | native-fullscreen | expose | scratchpad label", "Toggle a property on the focused window.", COMMAND_PALETTE_ARGUMENT_REQUIRED, false),
    COMMAND_PALETTE_ACTION("window.sub-layer", "Set Window Sub-layer", "Window", DOMAIN_WINDOW, COMMAND_WINDOW_SUB_LAYER, "below | normal | above | auto", "Set the focused window stacking sub-layer.", COMMAND_PALETTE_ARGUMENT_REQUIRED, false),
    COMMAND_PALETTE_ACTION("window.opacity", "Set Window Opacity", "Window", DOMAIN_WINDOW, COMMAND_WINDOW_OPACITY, "0.0 .. 1.0", "Set the focused window opacity.", COMMAND_PALETTE_ARGUMENT_REQUIRED, false),
    COMMAND_PALETTE_ACTION("window.raise", "Raise Window", "Window", DOMAIN_WINDOW, COMMAND_WINDOW_RAISE, NULL, "Raise the focused window.", COMMAND_PALETTE_ARGUMENT_NONE, false),
    COMMAND_PALETTE_ACTION("window.lower", "Lower Window", "Window", DOMAIN_WINDOW, COMMAND_WINDOW_LOWER, NULL, "Lower the focused window.", COMMAND_PALETTE_ARGUMENT_NONE, false),
    COMMAND_PALETTE_ACTION("window.scratchpad", "Set Window Scratchpad", "Window", DOMAIN_WINDOW, COMMAND_WINDOW_SCRATCHPAD, "LABEL | recover", "Set a scratchpad label, leave empty to clear, or recover all scratchpads.", COMMAND_PALETTE_ARGUMENT_OPTIONAL, false),
    COMMAND_PALETTE_ACTION("window.stack-selector-anchor", "Set Stack Selector Anchor", "Window", DOMAIN_WINDOW, COMMAND_WINDOW_STACK_SELECTOR_ANCHOR, "anchor | next | prev | default", "Set the focused stack selector anchor.", COMMAND_PALETTE_ARGUMENT_REQUIRED, false),

    COMMAND_PALETTE_ACTION("config.mouse-follows-focus", "Set Mouse Follows Focus", "Setting", DOMAIN_CONFIG, COMMAND_CONFIG_MFF, "on | off", "Move the pointer when window focus changes.", COMMAND_PALETTE_ARGUMENT_REQUIRED, false),
    COMMAND_PALETTE_ACTION("config.focus-follows-mouse", "Set Focus Follows Mouse", "Setting", DOMAIN_CONFIG, COMMAND_CONFIG_FFM, "autofocus | autoraise | off", "Set focus-follows-mouse behavior.", COMMAND_PALETTE_ARGUMENT_REQUIRED, false),
    COMMAND_PALETTE_ACTION("config.stack-selector", "Toggle Stack Selector", "Setting", DOMAIN_CONFIG, COMMAND_CONFIG_STACK_SELECTOR, "on | off", "Enable or disable stack selectors.", COMMAND_PALETTE_ARGUMENT_REQUIRED, false),
    COMMAND_PALETTE_ACTION("config.stack-selector-anchor", "Set Default Stack Selector Anchor", "Setting", DOMAIN_CONFIG, COMMAND_CONFIG_STACK_SELECTOR_ANCHOR, "STACK_SELECTOR_ANCHOR", "Set the default stack selector anchor.", COMMAND_PALETTE_ARGUMENT_REQUIRED, false),
    COMMAND_PALETTE_ACTION("config.skip-window-focus-animation", "Set Focus Animation Bypass", "Setting", DOMAIN_CONFIG, COMMAND_CONFIG_SKIP_SPACE_ANIMATION, "on | off", "Enable or disable window focus animation bypass.", COMMAND_PALETTE_ARGUMENT_REQUIRED, false),
    COMMAND_PALETTE_ACTION("config.layout", "Set Default Space Layout", "Setting", DOMAIN_CONFIG, COMMAND_CONFIG_LAYOUT, "bsp | stack | float", "Set the focused space layout setting.", COMMAND_PALETTE_ARGUMENT_REQUIRED, false),
    COMMAND_PALETTE_ACTION("config.split-type", "Set Default Split Type", "Setting", DOMAIN_CONFIG, COMMAND_CONFIG_SPLIT_TYPE, "vertical | horizontal | auto", "Set the focused space split type.", COMMAND_PALETTE_ARGUMENT_REQUIRED, false),
    COMMAND_PALETTE_ACTION("config.split-ratio", "Set Default Split Ratio", "Setting", DOMAIN_CONFIG, COMMAND_CONFIG_SPLIT_RATIO, "FLOAT", "Set the default split ratio.", COMMAND_PALETTE_ARGUMENT_REQUIRED, false),
    COMMAND_PALETTE_ACTION("config.top-padding", "Set Top Padding", "Setting", DOMAIN_CONFIG, COMMAND_CONFIG_TOP_PADDING, "INTEGER", "Set focused-space top padding.", COMMAND_PALETTE_ARGUMENT_REQUIRED, false),
    COMMAND_PALETTE_ACTION("config.bottom-padding", "Set Bottom Padding", "Setting", DOMAIN_CONFIG, COMMAND_CONFIG_BOTTOM_PADDING, "INTEGER", "Set focused-space bottom padding.", COMMAND_PALETTE_ARGUMENT_REQUIRED, false),
    COMMAND_PALETTE_ACTION("config.left-padding", "Set Left Padding", "Setting", DOMAIN_CONFIG, COMMAND_CONFIG_LEFT_PADDING, "INTEGER", "Set focused-space left padding.", COMMAND_PALETTE_ARGUMENT_REQUIRED, false),
    COMMAND_PALETTE_ACTION("config.right-padding", "Set Right Padding", "Setting", DOMAIN_CONFIG, COMMAND_CONFIG_RIGHT_PADDING, "INTEGER", "Set focused-space right padding.", COMMAND_PALETTE_ARGUMENT_REQUIRED, false),
    COMMAND_PALETTE_ACTION("config.window-gap", "Set Window Gap", "Setting", DOMAIN_CONFIG, COMMAND_CONFIG_WINDOW_GAP, "INTEGER", "Set the focused-space window gap.", COMMAND_PALETTE_ARGUMENT_REQUIRED, false),
    COMMAND_PALETTE_ACTION("config.auto-balance", "Set Auto Balance", "Setting", DOMAIN_CONFIG, COMMAND_CONFIG_AUTO_BALANCE, "on | off | x-axis | y-axis", "Set focused-space automatic balancing.", COMMAND_PALETTE_ARGUMENT_REQUIRED, false),
};

const int g_command_palette_action_count = array_count(g_command_palette_actions);

#undef COMMAND_PALETTE_ACTION

const struct command_palette_action *command_palette_find_action(char *identifier)
{
    if (!identifier) return NULL;

    for (int i = 0; i < g_command_palette_action_count; ++i) {
        if (string_equals(g_command_palette_actions[i].identifier, identifier)) {
            return &g_command_palette_actions[i];
        }
    }
    return NULL;
}

static int command_palette_string_score(char *text, char *query)
{
    if (!text || !*text || !query || !*query) return 0;

    size_t query_length = strlen(query);
    if (strncasecmp(text, query, query_length) == 0) {
        return 100;
    }

    char *found = strcasestr(text, query);
    if (!found) return 0;

    if (found > text) {
        char previous = found[-1];
        bool separator = previous == ' ' || previous == '-' || previous == '.' ||
                         previous == '_' || previous == '/' || previous == ':';
        if (separator) return 60;
    }

    return 30;
}

int command_palette_action_score(const struct command_palette_action *action, char *query)
{
    if (!action) return 0;
    if (!query || !*query) return 1;

    int score = 0;
    score += command_palette_string_score(action->identifier, query) * 8;
    score += command_palette_string_score(action->title, query) * 6;
    score += command_palette_string_score(action->syntax, query) * 3;
    score += command_palette_string_score(action->category, query) * 1;
    return score;
}

struct command_palette_scored_action
{
    const struct command_palette_action *action;
    int score;
    int index;
};

static int command_palette_scored_compare(const void *a, const void *b)
{
    const struct command_palette_scored_action *left = a;
    const struct command_palette_scored_action *right = b;

    if (left->score != right->score) return right->score - left->score;
    return left->index - right->index;
}

char *command_palette_build_message(const struct command_palette_action *action, char *argument, int *length)
{
    if (!action || action->kind != COMMAND_PALETTE_ACTION_IPC) return NULL;

    bool has_argument = argument && *argument;
    int domain_length = strlen(action->domain);
    int command_length = strlen(action->command);
    int argument_length = has_argument ? strlen(argument) : 0;
    int message_length = domain_length + command_length + argument_length + (has_argument ? 4 : 3);
    char *message = calloc(1, message_length);
    char *at = message;

    memcpy(at, action->domain, domain_length);
    at += domain_length + 1;
    memcpy(at, action->command, command_length);
    at += command_length + 1;
    if (has_argument) {
        memcpy(at, argument, argument_length);
        at += argument_length + 1;
    }
    *at = '\0';

    if (length) *length = message_length;
    return message;
}

static void command_palette_execute_action(FILE *rsp, const struct command_palette_action *action, char *argument, bool from_ui, uint64_t sid)
{
    if (action->kind == COMMAND_PALETTE_ACTION_NATIVE) {
        if (!from_ui && argument && *argument) {
            daemon_fail(rsp, "native action '%s' does not accept an argument.\n", action->identifier);
        } else if (from_ui) {
            space_workflow_submit(action->native_action, sid, argument);
        } else {
            space_workflow_present(action->native_action, false);
        }
        return;
    }

    bool has_argument = argument && *argument;
    if (action->argument_mode == COMMAND_PALETTE_ARGUMENT_REQUIRED && !has_argument) {
        daemon_fail(rsp, "action '%s' requires an argument matching '%s'.\n", action->identifier, action->syntax);
        return;
    }
    if (action->argument_mode == COMMAND_PALETTE_ARGUMENT_NONE && has_argument) {
        daemon_fail(rsp, "action '%s' does not accept an argument.\n", action->identifier);
        return;
    }

    char *message = command_palette_build_message(action, argument, NULL);
    handle_message(rsp, message);
    free(message);
}

static void command_palette_list_actions(FILE *rsp)
{
    fprintf(rsp, "[\n");
    for (int i = 0; i < g_command_palette_action_count; ++i) {
        const struct command_palette_action *action = &g_command_palette_actions[i];
        fprintf(rsp,
                "\t{\"id\":\"%s\",\"title\":\"%s\",\"category\":\"%s\",\"kind\":\"%s\",\"argument\":\"%s\",\"syntax\":%s%s%s,\"destructive\":%s}%s\n",
                action->identifier,
                action->title,
                action->category,
                action->kind == COMMAND_PALETTE_ACTION_NATIVE ? "native" : "ipc",
                action->argument_mode == COMMAND_PALETTE_ARGUMENT_NONE ? "none" : action->argument_mode == COMMAND_PALETTE_ARGUMENT_REQUIRED ? "required" : "optional",
                action->syntax ? "\"" : "",
                action->syntax ? action->syntax : "null",
                action->syntax ? "\"" : "",
                json_bool(action->destructive),
                i == g_command_palette_action_count - 1 ? "" : ",");
    }
    fprintf(rsp, "]\n");
}

#define COMMAND_ACTION_SHOW "--show"
#define COMMAND_ACTION_RUN  "--run"
#define COMMAND_ACTION_LIST "--list"

void command_palette_handle_message(FILE *rsp, char *message)
{
    struct token command = get_token(&message);
    if (token_equals(command, COMMAND_ACTION_SHOW)) {
        command_palette_show();
    } else if (token_equals(command, COMMAND_ACTION_RUN)) {
        struct token identifier = get_token(&message);
        if (!token_is_valid(identifier)) {
            daemon_fail(rsp, "action --run requires an action id.\n");
            return;
        }

        const struct command_palette_action *action = command_palette_find_action(identifier.text);
        if (!action) {
            daemon_fail(rsp, "unknown action '%.*s'.\n", identifier.length, identifier.text);
            return;
        }

        struct token argument = get_token(&message);
        struct token extra = get_token(&message);
        if (token_is_valid(extra)) {
            daemon_fail(rsp, "action '%s' accepts at most one argument.\n", action->identifier);
            return;
        }
        command_palette_execute_action(rsp, action, token_is_valid(argument) ? argument.text : NULL, false, 0);
    } else if (token_equals(command, COMMAND_ACTION_LIST)) {
        command_palette_list_actions(rsp);
    } else {
        daemon_fail(rsp, "unknown command '%.*s' for domain 'action'\n", command.length, command.text);
    }
}

#define COMMAND_PALETTE_WIDTH 650.0f
#define COMMAND_PALETTE_LIST_HEIGHT 400.0f
#define COMMAND_PALETTE_INPUT_HEIGHT 300.0f
#define COMMAND_PALETTE_CONFIRM_HEIGHT 236.0f

enum command_palette_view_state
{
    COMMAND_PALETTE_VIEW_LIST,
    COMMAND_PALETTE_VIEW_INPUT,
    COMMAND_PALETTE_VIEW_CONFIRMATION,
};

enum command_palette_content
{
    COMMAND_PALETTE_CONTENT_ACTIONS,
    COMMAND_PALETTE_CONTENT_SPACES,
    COMMAND_PALETTE_CONTENT_PICKER,
};

@class command_palette_controller;

@interface command_palette_panel : NSPanel {
    command_palette_controller *_paletteController;
}
@property(assign) command_palette_controller *paletteController;
@end

@interface command_palette_controller : NSObject <NSWindowDelegate, NSTableViewDataSource, NSTableViewDelegate, NSSearchFieldDelegate, NSTextFieldDelegate> {
    command_palette_panel *_panel;
    NSView *_listView;
    NSView *_detailView;
    NSSearchField *_searchField;
    NSTableView *_tableView;
    NSMutableArray *_filteredActions;
    NSMutableArray *_spaceItems;
    NSMutableArray *_pickerItems;
    NSMutableArray *_enumTokens;
    NSTextField *_sectionField;
    NSTextField *_footerField;
    NSButton *_backButton;
    NSTextField *_breadcrumbField;
    NSTextField *_detailTitleField;
    NSTextField *_detailIdField;
    NSTextField *_detailDescriptionField;
    NSTextField *_argumentLabelField;
    NSTextField *_argumentField;
    NSButton *_cancelButton;
    NSButton *_runButton;
    NSView *_listFooterBar;
    NSView *_detailFooterBar;
    const struct command_palette_action *_pendingAction;
    const struct command_palette_action *_pickerAction;
    enum command_palette_picker_kind _pickerKind;
    NSString *_pendingArgument;
    enum command_palette_view_state _state;
    enum command_palette_content _content;
    bool _workflowNested;
    uint64_t _workflowFocusedSid;
    bool _executing;
    NSInteger _hoveredRow;
    NSPoint _lastMouseLocation;
}
+ (instancetype)sharedController;
- (void)show;
- (void)cancelPalette:(id)sender;
- (void)showExecutionResult:(NSString *)output success:(bool)success;
@end

@implementation command_palette_panel
@synthesize paletteController = _paletteController;

- (BOOL)canBecomeKeyWindow
{
    return YES;
}

- (BOOL)canBecomeMainWindow
{
    return NO;
}

- (void)keyDown:(NSEvent *)event
{
    if (event.keyCode == 53) {
        [_paletteController cancelPalette:self];
    } else {
        [super keyDown:event];
    }
}
@end

@implementation command_palette_controller
+ (instancetype)sharedController
{
    static command_palette_controller *controller;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        controller = [[command_palette_controller alloc] init];
    });
    return controller;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _filteredActions = [[NSMutableArray alloc] initWithCapacity:g_command_palette_action_count];
        _spaceItems = [[NSMutableArray alloc] init];
        _pickerItems = [[NSMutableArray alloc] init];
        _enumTokens = [[NSMutableArray alloc] init];
        _pickerKind = COMMAND_PALETTE_PICKER_NONE;
        _state = COMMAND_PALETTE_VIEW_LIST;
        _content = COMMAND_PALETTE_CONTENT_ACTIONS;
        _hoveredRow = -1;
    }
    return self;
}

- (void)dealloc
{
    [_panel close];
    [_panel release];
    [_filteredActions release];
    [_spaceItems release];
    [_pickerItems release];
    [_enumTokens release];
    [_pendingArgument release];
    [super dealloc];
}

- (NSTextField *)labelWithFrame:(NSRect)frame
                          value:(NSString *)value
                           font:(NSFont *)font
                          color:(NSColor *)color
{
    NSTextField *field = [NSTextField labelWithString:value ?: @""];
    field.frame = frame;
    field.font = font;
    field.textColor = color;
    field.lineBreakMode = NSLineBreakByTruncatingTail;
    return field;
}

- (NSImageView *)keyIconWithSymbolName:(NSString *)symbolName
{
    NSImage *image = [NSImage imageWithSystemSymbolName:symbolName accessibilityDescription:nil];
    image = [image imageWithSymbolConfiguration:[NSImageSymbolConfiguration configurationWithPointSize:13.0f weight:NSFontWeightMedium]];

    NSSize natural = image.size;
    CGFloat width = MAX(14.0f, ceil(natural.width));

    NSImageView *view = [[NSImageView alloc] initWithFrame:NSMakeRect(0, 0, width, 18)];
    view.image = image;
    view.imageScaling = NSImageScaleProportionallyDown;
    view.contentTintColor = NSColor.secondaryLabelColor;
    return view;
}

- (void)addKeyHintToBar:(NSView *)bar
         keySymbolNames:(NSArray *)symbolNames
                   text:(NSString *)text
                    atX:(CGFloat *)x
{
    for (NSString *symbolName in symbolNames) {
        NSImageView *icon = [self keyIconWithSymbolName:symbolName];
        icon.frame = NSMakeRect(*x, 0, icon.frame.size.width, bar.frame.size.height);
        [bar addSubview:icon];
        [icon release];
        *x += icon.frame.size.width + 4.0f;
    }

    if (text.length) {
        NSTextField *label = [NSTextField labelWithString:text];
        label.font = [NSFont systemFontOfSize:11.0f];
        label.textColor = NSColor.secondaryLabelColor;
        [label sizeToFit];
        label.frame = NSMakeRect(*x, 0, label.frame.size.width, bar.frame.size.height);
        [bar addSubview:label];
        *x += label.frame.size.width + 16.0f;
    }
}

- (void)setRightHintForBar:(NSView *)bar keySymbolName:(NSString *)symbolName text:(NSString *)text
{
    NSImageView *icon = [self keyIconWithSymbolName:symbolName];
    NSTextField *label = [NSTextField labelWithString:text];
    label.font = [NSFont systemFontOfSize:11.0f];
    label.textColor = NSColor.secondaryLabelColor;
    [label sizeToFit];

    CGFloat total = icon.frame.size.width + 4.0f + label.frame.size.width;
    CGFloat x = bar.frame.size.width - total;
    icon.frame = NSMakeRect(x, 0, icon.frame.size.width, bar.frame.size.height);
    [bar addSubview:icon];
    [icon release];
    label.frame = NSMakeRect(x + icon.frame.size.width + 4.0f, 0, label.frame.size.width, bar.frame.size.height);
    [bar addSubview:label];
}

- (void)rebuildListFooter
{
    [[_listFooterBar subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];

    NSString *verb = @"run";
    if (_content == COMMAND_PALETTE_CONTENT_SPACES) {
        NSInteger row = _tableView.selectedRow;
        native_palette_item *item = row >= 0 && row < (NSInteger)_filteredActions.count ? _filteredActions[row] : nil;
        verb = item.kind == NATIVE_PALETTE_ITEM_CREATE_SPACE ? @"create" : @"focus";
    } else if (_content == COMMAND_PALETTE_CONTENT_PICKER) {
        verb = @"select";
    }

    CGFloat x = 0;
    [self addKeyHintToBar:_listFooterBar keySymbolNames:@[@"arrow.up", @"arrow.down"] text:@"navigate" atX:&x];
    [self addKeyHintToBar:_listFooterBar keySymbolNames:@[@"return"] text:verb atX:&x];
    NSString *escape = (_content == COMMAND_PALETTE_CONTENT_SPACES && _workflowNested) ||
                       _content == COMMAND_PALETTE_CONTENT_PICKER ? @"back" : @"close";
    [self setRightHintForBar:_listFooterBar keySymbolName:@"escape" text:escape];
}

- (void)rebuildDetailFooter
{
    [[_detailFooterBar subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];

    NSString *action = _state == COMMAND_PALETTE_VIEW_CONFIRMATION ? @"confirm" : _runButton.title.lowercaseString;
    NSString *escape = _pendingAction && _pendingAction->kind == COMMAND_PALETTE_ACTION_NATIVE && !_workflowNested ? @"close" : @"back";
    CGFloat x = 0;
    [self addKeyHintToBar:_detailFooterBar keySymbolNames:@[@"return"] text:action atX:&x];
    [self setRightHintForBar:_detailFooterBar keySymbolName:@"escape" text:escape];
}

- (void)buildPanel
{
    if (_panel) return;

    _panel = [[command_palette_panel alloc] initWithContentRect:NSMakeRect(0, 0, COMMAND_PALETTE_WIDTH, COMMAND_PALETTE_LIST_HEIGHT)
                                                      styleMask:NSWindowStyleMaskBorderless | NSWindowStyleMaskNonactivatingPanel
                                                        backing:NSBackingStoreBuffered
                                                          defer:NO];
    _panel.paletteController = self;
    _panel.delegate = self;
    _panel.opaque = NO;
    _panel.backgroundColor = NSColor.clearColor;
    _panel.hasShadow = YES;
    _panel.hidesOnDeactivate = NO;
    _panel.releasedWhenClosed = NO;
    _panel.floatingPanel = YES;
    _panel.becomesKeyOnlyIfNeeded = NO;
    _panel.animationBehavior = NSWindowAnimationBehaviorUtilityWindow;
    _panel.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces | NSWindowCollectionBehaviorTransient | NSWindowCollectionBehaviorFullScreenAuxiliary;
    _panel.level = NSStatusWindowLevel;
    _panel.acceptsMouseMovedEvents = YES;

    NSView *root = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, COMMAND_PALETTE_WIDTH, COMMAND_PALETTE_LIST_HEIGHT)];
    root.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    if (@available(macOS 27.0, *)) {
        NSGlassEffectView *glass = [[NSGlassEffectView alloc] initWithFrame:root.bounds];
        glass.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        glass.style = NSGlassEffectViewStyleRegular;
        glass.cornerRadius = 18.0f;
        glass.clipsToBounds = YES;
        glass.effectIsInteractive = YES;
        glass.contentView = root;
        _panel.contentView = glass;
        [glass release];
    } else {
        NSVisualEffectView *effect = [[NSVisualEffectView alloc] initWithFrame:root.bounds];
        effect.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        effect.material = NSVisualEffectMaterialHUDWindow;
        effect.blendingMode = NSVisualEffectBlendingModeBehindWindow;
        effect.state = NSVisualEffectStateActive;
        effect.maskImage = nil;
        [effect addSubview:root];
        _panel.contentView = effect;
        [effect release];
    }

    _listView = [[NSView alloc] initWithFrame:root.bounds];
    _listView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    [root addSubview:_listView];

    _searchField = [[NSSearchField alloc] initWithFrame:NSMakeRect(14, 348, 622, 36)];
    _searchField.placeholderString = @"Search Yabai actions…";
    _searchField.font = [NSFont systemFontOfSize:15.0f];
    _searchField.delegate = self;
    [_listView addSubview:_searchField];

    _backButton = [[NSButton alloc] initWithFrame:NSMakeRect(12, 351, 28, 30)];
    _backButton.image = [NSImage imageWithSystemSymbolName:@"chevron.left" accessibilityDescription:nil];
    _backButton.imagePosition = NSImageOnly;
    _backButton.bezelStyle = NSBezelStyleRounded;
    _backButton.bordered = NO;
    _backButton.title = @"";
    _backButton.target = self;
    _backButton.action = @selector(backToActions:);
    _backButton.hidden = YES;
    [_listView addSubview:_backButton];

    _sectionField = [self labelWithFrame:NSMakeRect(18, 322, 606, 14)
                                   value:@"ACTIONS"
                                    font:[NSFont systemFontOfSize:10.0f weight:NSFontWeightSemibold]
                                   color:NSColor.tertiaryLabelColor];
    [_listView addSubview:_sectionField];

    NSScrollView *scroll = [[NSScrollView alloc] initWithFrame:NSMakeRect(8, 42, 634, 268)];
    scroll.drawsBackground = NO;
    scroll.hasVerticalScroller = YES;
    scroll.autohidesScrollers = YES;
    scroll.scrollerStyle = NSScrollerStyleOverlay;
    scroll.borderType = NSNoBorder;

    _tableView = [[NSTableView alloc] initWithFrame:scroll.bounds];
    NSTableColumn *column = [[NSTableColumn alloc] initWithIdentifier:@"action"];
    column.width = 634.0f;
    column.resizingMask = NSTableColumnAutoresizingMask;
    [_tableView addTableColumn:column];
    [column release];
    _tableView.headerView = nil;
    _tableView.backgroundColor = NSColor.clearColor;
    _tableView.rowHeight = 44.0f;
    _tableView.intercellSpacing = NSMakeSize(0, 1);
    _tableView.columnAutoresizingStyle = NSTableViewUniformColumnAutoresizingStyle;
    _tableView.selectionHighlightStyle = NSTableViewSelectionHighlightStyleNone;
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.target = self;
    _tableView.action = @selector(tableAction:);
    scroll.documentView = _tableView;
    [_listView addSubview:scroll];
    [scroll release];

    NSTrackingArea *tracking_area = [[NSTrackingArea alloc] initWithRect:NSZeroRect
                                                                 options:NSTrackingActiveAlways | NSTrackingMouseMoved | NSTrackingMouseEnteredAndExited | NSTrackingInVisibleRect
                                                                   owner:self
                                                                userInfo:nil];
    [_tableView addTrackingArea:tracking_area];
    [tracking_area release];

    _footerField = [self labelWithFrame:NSMakeRect(14, 12, 622, 18)
                                  value:@""
                                   font:[NSFont systemFontOfSize:11.0f]
                                  color:NSColor.tertiaryLabelColor];
    _footerField.hidden = YES;
    [_listView addSubview:_footerField];

    _listFooterBar = [[NSView alloc] initWithFrame:NSMakeRect(14, 12, 622, 18)];
    [_listView addSubview:_listFooterBar];
    [_listFooterBar release];

    _detailView = [[NSView alloc] initWithFrame:root.bounds];
    _detailView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    _detailView.hidden = YES;
    [root addSubview:_detailView];

    _breadcrumbField = [self labelWithFrame:NSMakeRect(22, 262, 606, 16)
                                      value:@"Yabai Actions  ›  Argument"
                                       font:[NSFont systemFontOfSize:12.0f]
                                      color:NSColor.secondaryLabelColor];
    [_detailView addSubview:_breadcrumbField];

    _detailTitleField = [self labelWithFrame:NSMakeRect(22, 228, 606, 28)
                                       value:@""
                                        font:[NSFont systemFontOfSize:21.0f weight:NSFontWeightSemibold]
                                       color:NSColor.labelColor];
    [_detailView addSubview:_detailTitleField];

    _detailIdField = [self labelWithFrame:NSMakeRect(22, 206, 606, 18)
                                    value:@""
                                     font:[NSFont monospacedSystemFontOfSize:12.0f weight:NSFontWeightRegular]
                                    color:NSColor.controlAccentColor];
    [_detailView addSubview:_detailIdField];

    _detailDescriptionField = [self labelWithFrame:NSMakeRect(22, 168, 606, 34)
                                             value:@""
                                              font:[NSFont systemFontOfSize:13.0f]
                                             color:NSColor.secondaryLabelColor];
    _detailDescriptionField.maximumNumberOfLines = 2;
    [_detailView addSubview:_detailDescriptionField];

    _argumentLabelField = [self labelWithFrame:NSMakeRect(22, 148, 606, 16)
                                         value:@"Argument"
                                          font:[NSFont systemFontOfSize:12.0f weight:NSFontWeightMedium]
                                         color:NSColor.secondaryLabelColor];
    [_detailView addSubview:_argumentLabelField];

    _argumentField = [[NSTextField alloc] initWithFrame:NSMakeRect(22, 98, 606, 40)];
    _argumentField.font = [NSFont systemFontOfSize:14.0f];
    _argumentField.delegate = self;
    [_detailView addSubview:_argumentField];

    _cancelButton = [[NSButton alloc] initWithFrame:NSMakeRect(460, 48, 78, 32)];
    _cancelButton.title = @"Cancel";
    _cancelButton.bezelStyle = NSBezelStyleRounded;
    _cancelButton.target = self;
    _cancelButton.action = @selector(cancelPalette:);
    [_detailView addSubview:_cancelButton];

    _runButton = [[NSButton alloc] initWithFrame:NSMakeRect(546, 48, 82, 32)];
    _runButton.title = @"Run";
    _runButton.bezelStyle = NSBezelStyleRounded;
    _runButton.keyEquivalent = @"\r";
    _runButton.target = self;
    _runButton.action = @selector(runPendingAction:);
    [_detailView addSubview:_runButton];

    _detailFooterBar = [[NSView alloc] initWithFrame:NSMakeRect(22, 16, 606, 18)];
    [_detailView addSubview:_detailFooterBar];
    [_detailFooterBar release];

    [root release];
    [self filterActions];
}

- (void)filterActions
{
    _hoveredRow = -1;
    [_filteredActions removeAllObjects];

    if (_content == COMMAND_PALETTE_CONTENT_ACTIONS) {
        char *query = (char *)_searchField.stringValue.UTF8String;
        struct command_palette_scored_action scored[g_command_palette_action_count];
        int match_count = 0;

        for (int i = 0; i < g_command_palette_action_count; ++i) {
            int score = command_palette_action_score(&g_command_palette_actions[i], query);
            if (score > 0) {
                scored[match_count].action = &g_command_palette_actions[i];
                scored[match_count].score = score;
                scored[match_count].index = i;
                ++match_count;
            }
        }

        qsort(scored, match_count, sizeof(scored[0]), command_palette_scored_compare);

        for (int i = 0; i < match_count; ++i) {
            const struct command_palette_action *action = scored[i].action;
            NSString *symbolName = [NSString stringWithUTF8String:string_equals(action->category, "Window") ? "macwindow" :
                                                               string_equals(action->category, "Space") ? "rectangle.3.group" :
                                                               string_equals(action->category, "Display") ? "display" : "gearshape"];
            NSString *identifier = [NSString stringWithUTF8String:action->identifier];
            enum command_palette_picker_kind picker_kind = command_palette_picker_kind_for_action(action);
            native_palette_item *item = [native_palette_item itemWithTitle:[NSString stringWithUTF8String:action->title]
                                                                    detail:identifier
                                                                  category:[NSString stringWithUTF8String:action->category]
                                                                symbolName:symbolName
                                                                      kind:NATIVE_PALETTE_ITEM_ACTION];
            switch (picker_kind) {
            case COMMAND_PALETTE_PICKER_WINDOW:
                item.badge = @"WINDOW_SEL";
                item.badgeStyle = NATIVE_PALETTE_BADGE_SELECTOR;
                break;
            case COMMAND_PALETTE_PICKER_SPACE:
                item.badge = @"SPACE_SEL";
                item.badgeStyle = NATIVE_PALETTE_BADGE_SELECTOR;
                break;
            case COMMAND_PALETTE_PICKER_DISPLAY:
                item.badge = @"DISPLAY_SEL";
                item.badgeStyle = NATIVE_PALETTE_BADGE_SELECTOR;
                break;
            case COMMAND_PALETTE_PICKER_ENUM:
                item.badge = @"enum";
                item.badgeStyle = NATIVE_PALETTE_BADGE_ENUM;
                break;
            default:
                if (action->kind == COMMAND_PALETTE_ACTION_NATIVE) {
                    item.badge = @"native";
                    item.badgeStyle = NATIVE_PALETTE_BADGE_NATIVE;
                } else if (action->argument_mode != COMMAND_PALETTE_ARGUMENT_NONE) {
                    item.badge = @"text";
                    item.badgeStyle = NATIVE_PALETTE_BADGE_TEXT;
                }
                break;
            }
            item.representedPointer = (void *)action;
            [_filteredActions addObject:item];
        }
    } else if (_content == COMMAND_PALETTE_CONTENT_SPACES) {
        NSString *query = [_searchField.stringValue stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        for (native_palette_item *item in _spaceItems) {
            if (!query.length ||
                [item.title rangeOfString:query options:NSCaseInsensitiveSearch].location != NSNotFound) {
                [_filteredActions addObject:item];
            }
        }

        if (query.length && _filteredActions.count == 0) {
            native_palette_item *item = [native_palette_item itemWithTitle:[NSString stringWithFormat:@"Create “%@”", query]
                                                                    detail:@"Create on the active display and focus"
                                                                  category:@"New Space"
                                                                symbolName:@"plus.circle"
                                                                      kind:NATIVE_PALETTE_ITEM_CREATE_SPACE];
            [_filteredActions addObject:item];
        }
    } else if (_content == COMMAND_PALETTE_CONTENT_PICKER) {
        NSString *query = [_searchField.stringValue stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        for (native_palette_item *item in _pickerItems) {
            if (!query.length ||
                [item.title rangeOfString:query options:NSCaseInsensitiveSearch].location != NSNotFound ||
                [item.category rangeOfString:query options:NSCaseInsensitiveSearch].location != NSNotFound) {
                [_filteredActions addObject:item];
            }
        }
    }

    [_tableView reloadData];
    if (_filteredActions.count) {
        [self selectPaletteRow:0];
        [self ensurePaletteRowVisible:0];
    } else {
        [self selectPaletteRow:-1];
    }
    if (_listFooterBar) [self rebuildListFooter];
}

- (void)layoutDetailView
{
    if (_state == COMMAND_PALETTE_VIEW_LIST) return;

    CGFloat height = _state == COMMAND_PALETTE_VIEW_CONFIRMATION
                   ? COMMAND_PALETTE_CONFIRM_HEIGHT
                   : COMMAND_PALETTE_INPUT_HEIGHT;

    _breadcrumbField.frame = NSMakeRect(22, height - 38, 606, 16);
    _detailTitleField.frame = NSMakeRect(22, height - 72, 606, 28);
    _detailIdField.frame = NSMakeRect(22, height - 94, 606, 18);
    _detailDescriptionField.frame = NSMakeRect(22, height - 132, 606, 34);

    if (_state == COMMAND_PALETTE_VIEW_CONFIRMATION) {
        _argumentLabelField.hidden = YES;
        _argumentField.hidden = YES;
    } else {
        _argumentLabelField.hidden = NO;
        _argumentField.hidden = NO;
        _argumentLabelField.frame = NSMakeRect(22, height - 152, 606, 16);
        _argumentField.frame = NSMakeRect(22, height - 202, 606, 40);
    }

    _cancelButton.frame = NSMakeRect(460, 48, 78, 32);
    _runButton.frame = NSMakeRect(546, 48, 82, 32);
    _detailFooterBar.frame = NSMakeRect(22, 16, 606, 18);
}

- (void)resizePanelForState
{
    [self layoutDetailView];

    CGFloat height = _state == COMMAND_PALETTE_VIEW_LIST ? COMMAND_PALETTE_LIST_HEIGHT
                   : _state == COMMAND_PALETTE_VIEW_CONFIRMATION ? COMMAND_PALETTE_CONFIRM_HEIGHT
                   : COMMAND_PALETTE_INPUT_HEIGHT;

    NSPoint mouse = NSEvent.mouseLocation;
    NSScreen *screen = NSScreen.mainScreen;
    for (NSScreen *candidate in NSScreen.screens) {
        if (NSPointInRect(mouse, candidate.frame)) {
            screen = candidate;
            break;
        }
    }

    NSRect visible = screen.visibleFrame;
    NSRect frame = _panel.frame;
    frame.size.width = COMMAND_PALETTE_WIDTH;
    frame.size.height = height;
    frame.origin.x = NSMidX(visible) - frame.size.width / 2.0f;
    frame.origin.y = NSMidY(visible) - frame.size.height / 2.0f + 40.0f;
    [_panel setFrame:frame display:YES];
}

- (const struct command_palette_action *)selectedAction
{
    NSInteger row = _tableView.selectedRow;
    if (_content != COMMAND_PALETTE_CONTENT_ACTIONS || row < 0 || row >= (NSInteger)_filteredActions.count) return NULL;
    return [(native_palette_item *)_filteredActions[row] representedPointer];
}

- (enum native_palette_row_visual_state)visualStateForRow:(NSInteger)row
{
    if (row == _tableView.selectedRow) return NATIVE_PALETTE_ROW_SELECTED;
    if (row == _hoveredRow) return NATIVE_PALETTE_ROW_HOVERED;
    return NATIVE_PALETTE_ROW_NONE;
}

- (void)syncVisibleRowStates
{
    NSRange visibleRows = [_tableView rowsInRect:_tableView.visibleRect];
    if (visibleRows.location == NSNotFound || visibleRows.length == 0) return;

    NSInteger lastRow = MIN((NSInteger)NSMaxRange(visibleRows), (NSInteger)_filteredActions.count);
    for (NSInteger row = visibleRows.location; row < lastRow; ++row) {
        NSTableRowView *view = [_tableView rowViewAtRow:row makeIfNecessary:NO];
        if ([view isKindOfClass:[native_palette_row class]]) {
            native_palette_row *paletteRow = (native_palette_row *)view;
            paletteRow.row = row;
            [paletteRow setVisualState:[self visualStateForRow:row]];
        }
    }
}

- (void)selectPaletteRow:(NSInteger)row
{
    if (row >= 0 && row < (NSInteger)_filteredActions.count) {
        [_tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
    } else {
        [_tableView deselectAll:nil];
    }
    [self syncVisibleRowStates];
}

- (void)ensurePaletteRowVisible:(NSInteger)row
{
    if (row < 0 || row >= (NSInteger)_filteredActions.count) return;

    NSScrollView *scrollView = _tableView.enclosingScrollView;
    NSClipView *clipView = scrollView.contentView;
    if (!clipView) return;

    NSRect visibleRect = _tableView.visibleRect;
    NSRect rowRect = [_tableView rectOfRow:row];
    CGFloat padding = _tableView.intercellSpacing.height;
    CGFloat targetY = visibleRect.origin.y;

    if (NSMinY(rowRect) - padding < NSMinY(visibleRect)) {
        targetY = NSMinY(rowRect) - padding;
    } else if (NSMaxY(rowRect) + padding > NSMaxY(visibleRect)) {
        targetY = NSMaxY(rowRect) + padding - NSHeight(visibleRect);
    } else {
        [self syncVisibleRowStates];
        return;
    }

    CGFloat maximumY = MAX(0.0f, NSHeight(_tableView.bounds) - NSHeight(visibleRect));
    targetY = MIN(MAX(0.0f, targetY), maximumY);
    [clipView scrollToPoint:NSMakePoint(visibleRect.origin.x, targetY)];
    [scrollView reflectScrolledClipView:clipView];
    [self syncVisibleRowStates];
}

- (void)showList
{
    _state = COMMAND_PALETTE_VIEW_LIST;
    _pendingAction = NULL;
    [_pendingArgument release];
    _pendingArgument = nil;
    _hoveredRow = -1;
    _detailView.hidden = YES;
    _listView.hidden = NO;
    _footerField.hidden = YES;
    _listFooterBar.hidden = NO;
    [self rebuildListFooter];
    [self resizePanelForState];
    [_panel makeFirstResponder:_searchField];
}

- (void)showInputForAction:(const struct command_palette_action *)action
{
    _state = COMMAND_PALETTE_VIEW_INPUT;
    _pendingAction = action;
    _listView.hidden = YES;
    _detailView.hidden = NO;
    _breadcrumbField.stringValue = @"Yabai Actions  ›  Argument";
    _detailTitleField.stringValue = [NSString stringWithUTF8String:action->title];
    _detailIdField.stringValue = [NSString stringWithUTF8String:action->identifier];
    _detailDescriptionField.stringValue = [NSString stringWithUTF8String:action->description];
    _argumentLabelField.stringValue = [NSString stringWithFormat:@"Argument  ·  %s", action->syntax ?: "text"];
    _argumentField.stringValue = @"";
    _argumentField.placeholderString = action->argument_mode == COMMAND_PALETTE_ARGUMENT_OPTIONAL ? @"Optional argument…" : @"Enter argument…";
    _runButton.title = @"Run";
    [self rebuildDetailFooter];
    [self resizePanelForState];
    [_panel makeFirstResponder:_argumentField];
}

- (void)showConfirmationForAction:(const struct command_palette_action *)action argument:(NSString *)argument
{
    _state = COMMAND_PALETTE_VIEW_CONFIRMATION;
    _pendingAction = action;
    [_pendingArgument release];
    _pendingArgument = [argument copy];
    _listView.hidden = YES;
    _detailView.hidden = NO;
    _breadcrumbField.stringValue = @"Yabai Actions  ›  Confirmation";
    _detailTitleField.stringValue = [NSString stringWithFormat:@"Confirm %@?", [NSString stringWithUTF8String:action->title]];
    _detailIdField.stringValue = [NSString stringWithUTF8String:action->identifier];
    _detailDescriptionField.stringValue = [NSString stringWithFormat:@"%@ This action cannot be undone.", [NSString stringWithUTF8String:action->description]];
    _runButton.title = @"Confirm";
    [self rebuildDetailFooter];
    [self resizePanelForState];
    [_panel makeFirstResponder:_runButton];
}

- (void)activateAction:(const struct command_palette_action *)action
{
    if (!action || _executing) return;
    if (action->kind == COMMAND_PALETTE_ACTION_NATIVE) {
        _executing = true;
        space_workflow_present(action->native_action, true);
        return;
    }

    enum command_palette_picker_kind picker_kind = command_palette_picker_kind_for_action(action);
    if (picker_kind != COMMAND_PALETTE_PICKER_NONE) {
        _pickerAction = action;
        _pickerKind = picker_kind;
        if (picker_kind == COMMAND_PALETTE_PICKER_ENUM) {
            [self buildEnumItemsForAction:action];
            [self preparePickerList];
            [self filterActions];
            [self showList];
        } else {
            _executing = true;
            space_workflow_present_picker(action->identifier, picker_kind);
        }
    } else if (action->argument_mode != COMMAND_PALETTE_ARGUMENT_NONE) {
        [self showInputForAction:action];
    } else if (action->destructive) {
        [self showConfirmationForAction:action argument:nil];
    } else {
        [self executeAction:action argument:nil];
    }
}

- (void)executeAction:(const struct command_palette_action *)action argument:(NSString *)argument
{
    if (_executing || !action) return;

    struct command_palette_execution_request *request = malloc(sizeof(struct command_palette_execution_request));
    request->action = action;
    request->argument = argument.length ? strdup(argument.UTF8String) : NULL;
    request->sid = _workflowFocusedSid;
    request->from_ui = true;
    _executing = true;
    event_loop_post(&g_event_loop, COMMAND_PALETTE_ACTION, request, 0);
}

- (void)runPendingAction:(id)sender
{
    if (!_pendingAction) return;

    if (_state == COMMAND_PALETTE_VIEW_INPUT) {
        NSString *argument = _argumentField.stringValue;
        if (_pendingAction->argument_mode == COMMAND_PALETTE_ARGUMENT_REQUIRED && !argument.length) {
            _argumentLabelField.stringValue = [NSString stringWithFormat:@"Argument required  ·  %s", _pendingAction->syntax ?: "text"];
            _argumentLabelField.textColor = NSColor.systemRedColor;
            NSBeep();
            return;
        }
        _argumentLabelField.textColor = NSColor.secondaryLabelColor;
        if (_pendingAction->destructive) {
            [self showConfirmationForAction:_pendingAction argument:argument];
        } else {
            [self executeAction:_pendingAction argument:argument];
        }
    } else if (_state == COMMAND_PALETTE_VIEW_CONFIRMATION) {
        [self executeAction:_pendingAction argument:_pendingArgument];
    }
}

- (void)activateSelectedRow
{
    NSInteger row = _tableView.selectedRow;
    if (row < 0 || row >= (NSInteger)_filteredActions.count) return;

    native_palette_item *item = _filteredActions[row];
    if (_content == COMMAND_PALETTE_CONTENT_ACTIONS) {
        [self activateAction:item.representedPointer];
    } else if (_content == COMMAND_PALETTE_CONTENT_PICKER) {
        [self activatePickerRow:item];
    } else if (item.kind == NATIVE_PALETTE_ITEM_CREATE_SPACE) {
        space_workflow_submit(COMMAND_PALETTE_NATIVE_SPACE_CHOOSE, 0, (char *)_searchField.stringValue.UTF8String);
        _executing = true;
    } else {
        space_workflow_submit(COMMAND_PALETTE_NATIVE_SPACE_CHOOSE, item.representedValue, NULL);
        _executing = true;
    }
}

- (NSString *)argumentForPickerItem:(native_palette_item *)item
{
    switch (_pickerKind) {
    case COMMAND_PALETTE_PICKER_WINDOW:
        return [NSString stringWithFormat:@"%u", (uint32_t)item.representedValue];
    case COMMAND_PALETTE_PICKER_SPACE:
    case COMMAND_PALETTE_PICKER_DISPLAY:
        return [NSString stringWithFormat:@"%d", (int)item.representedValue];
    case COMMAND_PALETTE_PICKER_ENUM:
        if (item.representedValue < (uint64_t)_enumTokens.count) {
            return _enumTokens[(NSUInteger)item.representedValue];
        }
        return nil;
    default:
        return nil;
    }
}

- (void)activatePickerRow:(native_palette_item *)item
{
    if (!_pickerAction || _executing) return;
    NSString *argument = [self argumentForPickerItem:item];
    if (!argument) return;
    [self executeAction:_pickerAction argument:argument];
}

- (NSString *)symbolNameForEnumToken:(NSString *)token
{
    NSString *lower = token.lowercaseString;
    if ([lower isEqualToString:@"stack"]) return @"rectangle.stack";
    if ([lower isEqualToString:@"bsp"]) return @"rectangle.split.2x1";
    if ([lower isEqualToString:@"float"]) return @"rectangle.inset.filled";
    if ([lower isEqualToString:@"on"]) return @"checkmark.circle";
    if ([lower isEqualToString:@"off"]) return @"circle";
    if ([lower isEqualToString:@"north"]) return @"arrow.up";
    if ([lower isEqualToString:@"south"]) return @"arrow.down";
    if ([lower isEqualToString:@"east"]) return @"arrow.right";
    if ([lower isEqualToString:@"west"]) return @"arrow.left";
    return @"circle";
}

- (void)buildEnumItemsForAction:(const struct command_palette_action *)action
{
    [_pickerItems removeAllObjects];
    [_enumTokens removeAllObjects];

    NSArray *tokens = nil;
    if (string_equals(action->syntax, "STACK_SELECTOR_ANCHOR")) {
        NSMutableArray *anchors = [NSMutableArray arrayWithCapacity:STACK_SELECTOR_ANCHOR_COUNT];
        for (int i = 0; i < STACK_SELECTOR_ANCHOR_COUNT; ++i) {
            [anchors addObject:[NSString stringWithUTF8String:g_stack_selector_anchor_str[i]]];
        }
        tokens = anchors;
    } else {
        tokens = [[NSString stringWithUTF8String:action->syntax] componentsSeparatedByString:@"|"];
    }

    for (NSString *token in tokens) {
        NSString *trimmed = [token stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
        if (!trimmed.length) continue;
        [_enumTokens addObject:trimmed];
        native_palette_item *item = [native_palette_item itemWithTitle:trimmed
                                                                detail:@""
                                                              category:@""
                                                            symbolName:[self symbolNameForEnumToken:trimmed]
                                                                  kind:NATIVE_PALETTE_ITEM_ACTION];
        item.representedValue = _enumTokens.count - 1;
        [_pickerItems addObject:item];
    }
}

- (void)preparePickerList
{
    _content = COMMAND_PALETTE_CONTENT_PICKER;
    _backButton.hidden = NO;
    _searchField.frame = NSMakeRect(46, 348, 590, 36);
    _searchField.stringValue = @"";

    NSString *kind_word = @"VALUE";
    switch (_pickerKind) {
    case COMMAND_PALETTE_PICKER_WINDOW:
        kind_word = @"WINDOW";
        _searchField.placeholderString = @"Search windows…";
        break;
    case COMMAND_PALETTE_PICKER_SPACE:
        kind_word = @"SPACE";
        _searchField.placeholderString = @"Search spaces…";
        break;
    case COMMAND_PALETTE_PICKER_DISPLAY:
        kind_word = @"DISPLAY";
        _searchField.placeholderString = @"Search displays…";
        break;
    case COMMAND_PALETTE_PICKER_ENUM:
        kind_word = @"VALUE";
        _searchField.placeholderString = @"Search values…";
        break;
    default:
        _searchField.placeholderString = @"Search…";
        break;
    }

    NSString *action_title = _pickerAction ? [NSString stringWithUTF8String:_pickerAction->title] : @"";
    _sectionField.stringValue = [[NSString stringWithFormat:@"%@ · CHOOSE %@", action_title, kind_word] uppercaseString];
}

- (void)showPicker:(struct space_workflow_picker_snapshot *)snapshot
{
    [self buildPanel];
    _executing = false;

    const struct command_palette_action *action = command_palette_find_action(snapshot->action_identifier);
    if (!action) {
        _pickerAction = NULL;
        return;
    }
    _pickerAction = action;
    _pickerKind = snapshot->kind;

    [_pickerItems removeAllObjects];
    [_enumTokens removeAllObjects];

    if (snapshot->kind == COMMAND_PALETTE_PICKER_WINDOW) {
        for (int i = 0; i < snapshot->window_count; ++i) {
            struct space_workflow_window_item *window = &snapshot->windows[i];
            if (window->wid == snapshot->focused_wid) continue;
            NSString *title = window->title && *window->title ? [NSString stringWithUTF8String:window->title] : @"Untitled";
            NSString *app = window->app && *window->app ? [NSString stringWithUTF8String:window->app] : @"Window";
            NSString *detail = [NSString stringWithFormat:@"Space %d", window->space_index];
            native_palette_item *item = [native_palette_item itemWithTitle:title
                                                                    detail:detail
                                                                  category:app
                                                                symbolName:@"macwindow"
                                                                      kind:NATIVE_PALETTE_ITEM_ACTION];
            NSImage *app_icon = nil;
            if (window->pid) {
                NSRunningApplication *application = [NSRunningApplication runningApplicationWithProcessIdentifier:window->pid];
                app_icon = application.icon;
            }
            if (app_icon) item.iconImage = app_icon;
            item.representedValue = window->wid;
            [_pickerItems addObject:item];
        }
    } else if (snapshot->kind == COMMAND_PALETTE_PICKER_SPACE) {
        for (int i = 0; i < snapshot->space_count; ++i) {
            struct space_workflow_space *space = &snapshot->spaces[i];
            NSString *title = space->label && *space->label
                            ? [NSString stringWithUTF8String:space->label]
                            : [NSString stringWithFormat:@"Space %d", space->index];
            NSString *detail = [NSString stringWithFormat:@"Display %d  ·  %@",
                                                           space->display_index,
                                                           [NSString stringWithUTF8String:view_type_str[space->layout]]];
            NSString *category = space->focused ? @"Current" : @"";
            native_palette_item *item = [native_palette_item itemWithTitle:title
                                                                    detail:detail
                                                                  category:category
                                                                symbolName:@"rectangle.3.group"
                                                                      kind:NATIVE_PALETTE_ITEM_ACTION];
            item.representedValue = space->index;
            [_pickerItems addObject:item];
        }
    } else if (snapshot->kind == COMMAND_PALETTE_PICKER_DISPLAY) {
        for (int i = 0; i < snapshot->display_count; ++i) {
            struct space_workflow_display_item *display = &snapshot->displays[i];
            NSString *title = [NSString stringWithFormat:@"Display %d", display->index];
            NSString *detail = [NSString stringWithFormat:@"%d × %d", display->w, display->h];
            native_palette_item *item = [native_palette_item itemWithTitle:title
                                                                    detail:detail
                                                                  category:@""
                                                                symbolName:@"display"
                                                                      kind:NATIVE_PALETTE_ITEM_ACTION];
            item.representedValue = display->index;
            [_pickerItems addObject:item];
        }
    }

    [self preparePickerList];
    [self filterActions];
    [self showList];
    [_panel makeKeyAndOrderFront:nil];
    [_panel orderFrontRegardless];
}

- (void)tableAction:(id)sender
{
    NSInteger row = _tableView.clickedRow;
    if (row >= 0 && row < (NSInteger)_filteredActions.count) {
        [self selectPaletteRow:row];
        [self activateSelectedRow];
    }
}

- (void)showActionList
{
    _content = COMMAND_PALETTE_CONTENT_ACTIONS;
    _workflowNested = false;
    _pickerAction = NULL;
    _pickerKind = COMMAND_PALETTE_PICKER_NONE;
    _backButton.hidden = YES;
    _searchField.frame = NSMakeRect(14, 348, 622, 36);
    _searchField.placeholderString = @"Search Yabai actions…";
    _sectionField.stringValue = @"ACTIONS";
    _searchField.stringValue = @"";
    [self filterActions];
    [self showList];
}

- (void)backToActions:(id)sender
{
    [self showActionList];
}

- (void)cancelPalette:(id)sender
{
    if (_state != COMMAND_PALETTE_VIEW_LIST) {
        if (_pendingAction && _pendingAction->kind == COMMAND_PALETTE_ACTION_NATIVE) {
            if (_workflowNested) [self showActionList]; else [_panel orderOut:nil];
        } else {
            [self showList];
        }
    } else if ((_content == COMMAND_PALETTE_CONTENT_SPACES && _workflowNested) ||
               _content == COMMAND_PALETTE_CONTENT_PICKER) {
        [self showActionList];
    } else {
        [_panel orderOut:nil];
    }
}

- (void)show
{
    [self buildPanel];
    _executing = false;
    [self showActionList];
    [_panel makeKeyAndOrderFront:nil];
    [_panel orderFrontRegardless];
    [_panel makeFirstResponder:_searchField];
}

- (void)showSpaceWorkflow:(struct space_workflow_snapshot *)snapshot
{
    [self buildPanel];
    _executing = false;
    _workflowNested = snapshot->nested;
    _workflowFocusedSid = snapshot->focused_sid;
    int focusedIndex = 0;
    for (int i = 0; i < snapshot->count; ++i) {
        if (snapshot->spaces[i].sid == snapshot->focused_sid) {
            focusedIndex = snapshot->spaces[i].index;
            break;
        }
    }

    if (snapshot->action == COMMAND_PALETTE_NATIVE_SPACE_CHOOSE) {
        [_spaceItems removeAllObjects];
        for (int i = 0; i < snapshot->count; ++i) {
            struct space_workflow_space *space = &snapshot->spaces[i];
            NSString *title = space->label && *space->label
                            ? [NSString stringWithUTF8String:space->label]
                            : [NSString stringWithFormat:@"Space %d", space->index];
            NSString *layout = space->user_space
                             ? [NSString stringWithUTF8String:view_type_str[space->layout]]
                             : @"fullscreen";
            NSString *windows = [NSString stringWithFormat:@"%d window%@", space->window_count, space->window_count == 1 ? @"" : @"s"];
            NSString *detail = [NSString stringWithFormat:@"Display %d  ·  %@  ·  %@",
                                                           space->display_index, layout, windows];
            NSString *category = space->focused ? @"Current" : @"";
            native_palette_item *item = [native_palette_item itemWithTitle:title
                                                                    detail:detail
                                                                  category:category
                                                                symbolName:@"rectangle.3.group"
                                                                      kind:NATIVE_PALETTE_ITEM_SPACE];
            item.representedValue = space->sid;
            [_spaceItems addObject:item];
        }

        _content = COMMAND_PALETTE_CONTENT_SPACES;
        _searchField.placeholderString = @"Switch or create a space…";
        _sectionField.stringValue = @"SPACES";
        _searchField.stringValue = @"";
        [self filterActions];
        for (NSInteger row = 0; row < (NSInteger)_filteredActions.count; ++row) {
            native_palette_item *item = _filteredActions[row];
            if (item.representedValue == snapshot->focused_sid) {
                [self selectPaletteRow:row];
                [self ensurePaletteRowVisible:row];
                break;
            }
        }
        [self showList];
    } else {
        const struct command_palette_action *action = command_palette_find_action("space.relabel");
        if (!action) return;

        [self showInputForAction:action];
        _breadcrumbField.stringValue = @"Yabai Actions  ›  Space  ›  Relabel";
        _argumentLabelField.stringValue = [NSString stringWithFormat:@"Label  ·  focused space %d", focusedIndex];
        _argumentLabelField.textColor = NSColor.secondaryLabelColor;
        _argumentField.stringValue = snapshot->focused_label ? [NSString stringWithUTF8String:snapshot->focused_label] : @"";
        _argumentField.placeholderString = @"Empty removes the current label";
        _runButton.title = @"Save";
        [self rebuildDetailFooter];
    }

    [_panel makeKeyAndOrderFront:nil];
    [_panel orderFrontRegardless];
}

- (void)showSpaceResult:(NSString *)message success:(bool)success closePanel:(bool)closePanel
{
    _executing = false;
    if (success && closePanel) {
        [_panel orderOut:nil];
        return;
    }

    if (_state == COMMAND_PALETTE_VIEW_INPUT) {
        _argumentLabelField.stringValue = message.length ? message : @"The space action failed.";
        _argumentLabelField.textColor = success ? NSColor.systemGreenColor : NSColor.systemRedColor;
        [_panel makeFirstResponder:_argumentField];
    } else {
        _listFooterBar.hidden = YES;
        _footerField.hidden = NO;
        _footerField.stringValue = message.length ? message : success ? @"Action completed." : @"Action failed.";
        _footerField.textColor = success ? NSColor.systemGreenColor : NSColor.systemRedColor;
    }
}

- (void)showExecutionResult:(NSString *)output success:(bool)success
{
    _executing = false;
    if (success && !output.length) {
        [_panel orderOut:nil];
        return;
    }

    [self showList];
    _listFooterBar.hidden = YES;
    _footerField.hidden = NO;
    _footerField.stringValue = output.length ? output : success ? @"Action completed." : @"Action failed.";
    _footerField.textColor = success ? NSColor.systemGreenColor : NSColor.systemRedColor;
}

- (void)windowDidResignKey:(NSNotification *)notification
{
    if (!_executing) [_panel orderOut:nil];
}

- (void)refreshHoverDisplay
{
    [self syncVisibleRowStates];
}

- (void)updateHoveredRowAtPoint:(NSPoint)point
{
    NSPoint local = [_tableView convertPoint:point fromView:nil];
    NSInteger row = [_tableView rowAtPoint:local];
    if (row >= (NSInteger)_filteredActions.count) row = -1;
    if (row == _hoveredRow) return;

    _hoveredRow = row;
    [self refreshHoverDisplay];
}

- (void)mouseMoved:(NSEvent *)event
{
    NSPoint location = event.locationInWindow;
    if (NSEqualPoints(location, _lastMouseLocation)) {
        return;
    }
    _lastMouseLocation = location;
    [self updateHoveredRowAtPoint:location];
}

- (void)mouseEntered:(NSEvent *)event
{
    _lastMouseLocation = event.locationInWindow;
    [self updateHoveredRowAtPoint:event.locationInWindow];
}

- (void)clearHover
{
    if (_hoveredRow == -1) return;

    _hoveredRow = -1;
    [self refreshHoverDisplay];
}

- (void)mouseExited:(NSEvent *)event
{
    [self clearHover];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return _filteredActions.count;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    [self syncVisibleRowStates];
    if (_content == COMMAND_PALETTE_CONTENT_SPACES) [self rebuildListFooter];
}

- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row
{
    native_palette_row *row_view = (native_palette_row *)[tableView makeViewWithIdentifier:@"command-palette-row-container" owner:self];
    if (!row_view) {
        row_view = [[native_palette_row alloc] initWithFrame:NSMakeRect(0, 0, 0, 0)];
        row_view.identifier = @"command-palette-row-container";
    }
    row_view.row = row;
    [row_view setVisualState:[self visualStateForRow:row]];
    return row_view;
}

- (NSView *)tableView:(NSTableView *)tableView
   viewForTableColumn:(NSTableColumn *)tableColumn
                  row:(NSInteger)row
{
    native_palette_row_view *view = [tableView makeViewWithIdentifier:@"command-palette-row" owner:self];
    if (!view) {
        view = [[[native_palette_row_view alloc] initWithFrame:NSMakeRect(0, 0, tableColumn.width, tableView.rowHeight)] autorelease];
        view.identifier = @"command-palette-row";
    }

    [view updateWithItem:_filteredActions[row]];
    return view;
}

- (void)controlTextDidChange:(NSNotification *)notification
{
    if (notification.object == _searchField) [self filterActions];
}

- (BOOL)control:(NSControl *)control
       textView:(NSTextView *)textView
doCommandBySelector:(SEL)commandSelector
{
    if (commandSelector == @selector(cancelOperation:)) {
        [self cancelPalette:control];
        return YES;
    }

    if (control == _searchField) {
        NSInteger row = _tableView.selectedRow;
        if (commandSelector == @selector(moveDown:)) {
            row = MIN(row + 1, (NSInteger)_filteredActions.count - 1);
        } else if (commandSelector == @selector(moveUp:)) {
            row = MAX(row - 1, 0);
        } else if (commandSelector == @selector(insertNewline:)) {
            [self activateSelectedRow];
            return YES;
        } else {
            return NO;
        }

        if (_filteredActions.count && row >= 0 && row < (NSInteger)_filteredActions.count) {
            [self clearHover];
            [self selectPaletteRow:row];
            [self ensurePaletteRowVisible:row];
            [self clearHover];
        }
        return YES;
    }

    if (control == _argumentField && commandSelector == @selector(insertNewline:)) {
        [self runPendingAction:control];
        return YES;
    }
    return NO;
}
@end

void command_palette_show(void)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[command_palette_controller sharedController] show];
    });
}

void command_palette_show_space_workflow(struct space_workflow_snapshot *snapshot)
{
    [[command_palette_controller sharedController] showSpaceWorkflow:snapshot];
    space_workflow_destroy_snapshot(snapshot);
}

void command_palette_show_space_result(char *message, bool success, bool close_panel)
{
    NSString *result = message && *message ? [NSString stringWithUTF8String:message] : @"";
    [[command_palette_controller sharedController] showSpaceResult:result success:success closePanel:close_panel];
}

void command_palette_execute_request(void *context)
{
    struct command_palette_execution_request *request = context;
    if (!request) return;

    if (request->action->kind == COMMAND_PALETTE_ACTION_NATIVE) {
        command_palette_execute_action(NULL, request->action, request->argument, request->from_ui, request->sid);
        free(request->argument);
        free(request);
        return;
    }

    FILE *rsp = tmpfile();
    if (!rsp) {
        free(request->argument);
        free(request);
        dispatch_async(dispatch_get_main_queue(), ^{
            [[command_palette_controller sharedController] showExecutionResult:@"Unable to capture action output." success:false];
        });
        return;
    }

    command_palette_execute_action(rsp, request->action, request->argument, request->from_ui, request->sid);
    fflush(rsp);
    long response_length = ftell(rsp);
    rewind(rsp);

    char *response = calloc(1, response_length + 1);
    if (response_length > 0) {
        fread(response, 1, response_length, rsp);
    }
    fclose(rsp);

    bool success = response_length == 0 || response[0] != FAILURE_MESSAGE[0];
    char *output = success ? response : response + 1;
    size_t output_length = strlen(output);
    while (output_length > 0 &&
           (output[output_length - 1] == '\n' || output[output_length - 1] == '\r')) {
        output[--output_length] = '\0';
    }

    free(request->argument);
    free(request);

    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *result = output[0] ? [NSString stringWithUTF8String:output] : @"";
        [[command_palette_controller sharedController] showExecutionResult:result success:success];
        free(response);
    });
}

enum command_palette_picker_kind command_palette_picker_kind_for_action(const struct command_palette_action *action)
{
    if (!action || !action->syntax) return COMMAND_PALETTE_PICKER_NONE;
    if (string_equals(action->syntax, "WINDOW_SEL")) return COMMAND_PALETTE_PICKER_WINDOW;
    if (string_equals(action->syntax, "SPACE_SEL")) return COMMAND_PALETTE_PICKER_SPACE;
    if (string_equals(action->syntax, "DISPLAY_SEL")) return COMMAND_PALETTE_PICKER_DISPLAY;
    if (string_equals(action->syntax, "STACK_SELECTOR_ANCHOR")) return COMMAND_PALETTE_PICKER_ENUM;
    if (strchr(action->syntax, '|')) return COMMAND_PALETTE_PICKER_ENUM;
    return COMMAND_PALETTE_PICKER_NONE;
}

void command_palette_show_picker(struct space_workflow_picker_snapshot *snapshot)
{
    [[command_palette_controller sharedController] showPicker:snapshot];
    space_workflow_destroy_picker_snapshot(snapshot);
}
