#ifndef SPACE_WORKFLOW_H
#define SPACE_WORKFLOW_H

enum space_workflow_request_type
{
    SPACE_WORKFLOW_PRESENT,
    SPACE_WORKFLOW_FOCUS,
    SPACE_WORKFLOW_CREATE_AND_FOCUS,
    SPACE_WORKFLOW_RELABEL,
    SPACE_WORKFLOW_LAYOUT_CYCLE,
    SPACE_WORKFLOW_SET_LAYOUT,
    SPACE_WORKFLOW_CREATE_TIMEOUT,
    SPACE_WORKFLOW_PRESENT_PICKER,
};

struct space_workflow_request
{
    enum space_workflow_request_type type;
    enum command_palette_native_action action;
    enum command_palette_picker_kind picker_kind;
    uint64_t sid;
    uint64_t generation;
    char *text;
    bool nested;
};

struct space_workflow_space
{
    uint64_t sid;
    int index;
    int display_index;
    uint32_t display_id;
    int window_count;
    enum view_type layout;
    bool focused;
    bool display_current;
    bool user_space;
    char *label;
};

struct space_workflow_snapshot
{
    struct space_workflow_space *spaces;
    int count;
    uint32_t *displays;
    int display_count;
    enum command_palette_native_action action;
    bool nested;
    uint64_t focused_sid;
    char *focused_label;
};

struct space_workflow_window_item
{
    uint32_t wid;
    uint32_t pid;
    char *app;
    char *title;
    uint64_t sid;
    int space_index;
};

struct space_workflow_display_item
{
    uint32_t did;
    int index;
    int x;
    int y;
    int w;
    int h;
};

struct space_workflow_picker_snapshot
{
    enum command_palette_picker_kind kind;
    char *action_identifier;
    struct space_workflow_space *spaces;
    int space_count;
    struct space_workflow_window_item *windows;
    int window_count;
    struct space_workflow_display_item *displays;
    int display_count;
    uint64_t focused_sid;
    uint32_t focused_wid;
};

enum view_type space_workflow_next_layout(enum view_type layout);
struct space_workflow_snapshot *space_workflow_create_space_snapshot(void);
void space_workflow_submit_layout(enum view_type layout);
void space_workflow_present(enum command_palette_native_action action, bool nested);
void space_workflow_submit(enum command_palette_native_action action, uint64_t sid, char *text);
void space_workflow_present_picker(const char *action_identifier, enum command_palette_picker_kind kind);
void command_palette_show_picker(struct space_workflow_picker_snapshot *snapshot);
void space_workflow_destroy_picker_snapshot(struct space_workflow_picker_snapshot *snapshot);
void space_workflow_handle_request(void *context);
void space_workflow_handle_space_created(uint64_t sid);
void space_workflow_destroy_snapshot(struct space_workflow_snapshot *snapshot);

#endif
