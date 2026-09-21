extern struct event_loop g_event_loop;
extern struct space_manager g_space_manager;
extern struct display_manager g_display_manager;

struct space_workflow_pending_create
{
    bool active;
    uint32_t did;
    uint64_t generation;
    char *label;
};

static struct space_workflow_pending_create g_space_workflow_pending_create;
static uint64_t g_space_workflow_generation;

static char *space_workflow_copy_string(char *string)
{
    return string && *string ? strdup(string) : NULL;
}

void space_workflow_destroy_snapshot(struct space_workflow_snapshot *snapshot)
{
    if (!snapshot) return;

    for (int i = 0; i < snapshot->count; ++i) {
        free(snapshot->spaces[i].label);
    }
    free(snapshot->spaces);
    free(snapshot->focused_label);
    free(snapshot);
}

static struct space_workflow_snapshot *space_workflow_create_snapshot(enum command_palette_native_action action, bool nested)
{
    struct space_workflow_snapshot *snapshot = calloc(1, sizeof(struct space_workflow_snapshot));
    snapshot->action = action;
    snapshot->nested = nested;
    snapshot->focused_sid = space_manager_active_space();

    struct space_label *focused_label = space_manager_get_label_for_space(&g_space_manager, snapshot->focused_sid);
    snapshot->focused_label = focused_label ? strdup(focused_label->label) : NULL;

    int display_count = 0;
    uint32_t *display_list = display_manager_active_display_list(&display_count);
    for (int display = 0; display < display_count; ++display) {
        uint32_t did = display_list[display];
        int space_count = 0;
        uint64_t *space_list = display_space_list(did, &space_count);
        for (int i = 0; i < space_count; ++i) {
            uint64_t sid = space_list[i];
            if (!space_is_user(sid) && !space_is_fullscreen(sid)) continue;

            snapshot->spaces = realloc(snapshot->spaces, sizeof(struct space_workflow_space) * (snapshot->count + 1));
            struct space_workflow_space *space = &snapshot->spaces[snapshot->count++];
            memset(space, 0, sizeof(*space));
            space->sid = sid;
            space->index = space_manager_mission_control_index(sid);
            space->display_index = display_manager_display_id_arrangement(did);
            space->focused = sid == snapshot->focused_sid;
            space->user_space = space_is_user(sid);

            struct view *view = space_manager_find_view(&g_space_manager, sid);
            space->layout = view ? view->layout : VIEW_FLOAT;

            int window_count = 0;
            space_window_list(sid, &window_count, false);
            space->window_count = window_count;

            struct space_label *label = space_manager_get_label_for_space(&g_space_manager, sid);
            space->label = label ? strdup(label->label) : NULL;
        }
    }

    return snapshot;
}

static void space_workflow_deliver_snapshot(struct space_workflow_snapshot *snapshot)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        command_palette_show_space_workflow(snapshot);
    });
}

static void space_workflow_deliver_result(const char *message, bool success, bool close_panel)
{
    char *copy = message ? strdup(message) : strdup("");
    dispatch_async(dispatch_get_main_queue(), ^{
        command_palette_show_space_result(copy, success, close_panel);
        free(copy);
    });
}

static const char *space_workflow_error_message(enum space_op_error error)
{
    switch (error) {
    case SPACE_OP_ERROR_SUCCESS:              return "";
    case SPACE_OP_ERROR_SAME_SPACE:           return "The selected space is already focused.";
    case SPACE_OP_ERROR_DISPLAY_IS_ANIMATING: return "The display is currently animating.";
    case SPACE_OP_ERROR_IN_MISSION_CONTROL:   return "This action is unavailable while Mission Control is active.";
    case SPACE_OP_ERROR_SCRIPTING_ADDITION:   return "The scripting addition could not complete the space action.";
    case SPACE_OP_ERROR_INVALID_TYPE:         return "The selected space type does not support this action.";
    default:                                  return "The space action could not be completed.";
    }
}

void space_workflow_present(enum command_palette_native_action action, bool nested)
{
    struct space_workflow_request *request = calloc(1, sizeof(struct space_workflow_request));
    request->type = SPACE_WORKFLOW_PRESENT;
    request->action = action;
    request->nested = nested;
    event_loop_post(&g_event_loop, SPACE_WORKFLOW_REQUEST, request, 0);
}

void space_workflow_submit(enum command_palette_native_action action, uint64_t sid, char *text)
{
    struct space_workflow_request *request = calloc(1, sizeof(struct space_workflow_request));
    request->action = action;
    request->sid = sid;
    request->text = space_workflow_copy_string(text);

    switch (action) {
    case COMMAND_PALETTE_NATIVE_SPACE_CHOOSE:
        request->type = sid ? SPACE_WORKFLOW_FOCUS : SPACE_WORKFLOW_CREATE_AND_FOCUS;
        break;
    case COMMAND_PALETTE_NATIVE_SPACE_RELABEL:
        request->type = SPACE_WORKFLOW_RELABEL;
        break;
    case COMMAND_PALETTE_NATIVE_SPACE_LAYOUT_CYCLE:
        request->type = SPACE_WORKFLOW_LAYOUT_CYCLE;
        break;
    default:
        free(request->text);
        free(request);
        return;
    }

    event_loop_post(&g_event_loop, SPACE_WORKFLOW_REQUEST, request, 0);
}

static void space_workflow_begin_create(struct space_workflow_request *request)
{
    if (g_space_workflow_pending_create.active) {
        space_workflow_deliver_result("A space creation request is already in progress.", false, false);
        return;
    }

    uint64_t active_sid = space_manager_active_space();
    g_space_workflow_pending_create.active = true;
    g_space_workflow_pending_create.did = space_display_id(active_sid);
    g_space_workflow_pending_create.generation = ++g_space_workflow_generation;
    g_space_workflow_pending_create.label = space_workflow_copy_string(request->text);

    enum space_op_error result = space_manager_add_space(active_sid);
    if (result != SPACE_OP_ERROR_SUCCESS) {
        free(g_space_workflow_pending_create.label);
        memset(&g_space_workflow_pending_create, 0, sizeof(g_space_workflow_pending_create));
        space_workflow_deliver_result(space_workflow_error_message(result), false, false);
        return;
    }

    struct space_workflow_request *timeout = calloc(1, sizeof(struct space_workflow_request));
    timeout->type = SPACE_WORKFLOW_CREATE_TIMEOUT;
    timeout->generation = g_space_workflow_pending_create.generation;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 4 * NSEC_PER_SEC), dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        event_loop_post(&g_event_loop, SPACE_WORKFLOW_REQUEST, timeout, 0);
    });
}

static void space_workflow_relabel(struct space_workflow_request *request)
{
    uint64_t sid = request->sid ? request->sid : space_manager_active_space();
    struct space_label *existing = space_manager_get_label_for_space(&g_space_manager, sid);
    if (existing) space_manager_remove_label_for_space(&g_space_manager, sid);
    if (request->text && *request->text) space_manager_set_label_for_space(&g_space_manager, sid, request->text);
    space_workflow_deliver_result("", true, true);
}

enum view_type space_workflow_next_layout(enum view_type layout)
{
    return layout == VIEW_STACK ? VIEW_BSP
         : layout == VIEW_BSP ? VIEW_FLOAT
         : VIEW_STACK;
}

static void space_workflow_cycle_layout(void)
{
    uint64_t sid = space_manager_active_space();
    if (!space_is_user(sid)) {
        space_workflow_deliver_result("Cannot change the layout of a macOS fullscreen space.", false, false);
        return;
    }

    struct view *view = space_manager_find_view(&g_space_manager, sid);
    enum view_type layout = space_workflow_next_layout(view->layout);
    view_set_flag(view, VIEW_LAYOUT);
    space_manager_set_layout_for_space(&g_space_manager, sid, layout);
    space_workflow_deliver_result("", true, true);
}

void space_workflow_handle_request(void *context)
{
    struct space_workflow_request *request = context;
    if (!request) return;

    switch (request->type) {
    case SPACE_WORKFLOW_PRESENT:
        if (request->action == COMMAND_PALETTE_NATIVE_SPACE_LAYOUT_CYCLE) {
            space_workflow_cycle_layout();
        } else {
            space_workflow_deliver_snapshot(space_workflow_create_snapshot(request->action, request->nested));
        }
        break;
    case SPACE_WORKFLOW_FOCUS: {
        enum space_op_error result = space_manager_focus_space(request->sid);
        if (result == SPACE_OP_ERROR_SUCCESS || result == SPACE_OP_ERROR_SAME_SPACE) {
            space_workflow_deliver_result("", true, true);
        } else {
            space_workflow_deliver_result(space_workflow_error_message(result), false, false);
        }
    } break;
    case SPACE_WORKFLOW_CREATE_AND_FOCUS:
        space_workflow_begin_create(request);
        break;
    case SPACE_WORKFLOW_RELABEL:
        space_workflow_relabel(request);
        break;
    case SPACE_WORKFLOW_LAYOUT_CYCLE:
        space_workflow_cycle_layout();
        break;
    case SPACE_WORKFLOW_CREATE_TIMEOUT:
        if (g_space_workflow_pending_create.active &&
            request->generation == g_space_workflow_pending_create.generation) {
            free(g_space_workflow_pending_create.label);
            memset(&g_space_workflow_pending_create, 0, sizeof(g_space_workflow_pending_create));
            space_workflow_deliver_result("Timed out while waiting for the new space.", false, false);
        }
        break;
    }

    free(request->text);
    free(request);
}

void space_workflow_handle_space_created(uint64_t sid)
{
    if (!g_space_workflow_pending_create.active) return;
    if (!space_is_user(sid)) return;
    if (space_display_id(sid) != g_space_workflow_pending_create.did) return;

    char *label = g_space_workflow_pending_create.label;
    g_space_workflow_pending_create.label = NULL;
    g_space_workflow_pending_create.active = false;

    if (label && *label) {
        space_manager_set_label_for_space(&g_space_manager, sid, label);
    } else {
        free(label);
    }
    enum space_op_error result = space_manager_focus_space(sid);

    if (result == SPACE_OP_ERROR_SUCCESS || result == SPACE_OP_ERROR_SAME_SPACE) {
        space_workflow_deliver_result("", true, true);
    } else {
        space_workflow_deliver_result(space_workflow_error_message(result), false, false);
    }
}
