#ifndef SPACE_WORKFLOW_H
#define SPACE_WORKFLOW_H

enum space_workflow_request_type
{
    SPACE_WORKFLOW_PRESENT,
    SPACE_WORKFLOW_FOCUS,
    SPACE_WORKFLOW_CREATE_AND_FOCUS,
    SPACE_WORKFLOW_RELABEL,
    SPACE_WORKFLOW_LAYOUT_CYCLE,
    SPACE_WORKFLOW_CREATE_TIMEOUT,
};

struct space_workflow_request
{
    enum space_workflow_request_type type;
    enum command_palette_native_action action;
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
    int window_count;
    enum view_type layout;
    bool focused;
    bool user_space;
    char *label;
};

struct space_workflow_snapshot
{
    struct space_workflow_space *spaces;
    int count;
    enum command_palette_native_action action;
    bool nested;
    uint64_t focused_sid;
    char *focused_label;
};

enum view_type space_workflow_next_layout(enum view_type layout);
void space_workflow_present(enum command_palette_native_action action, bool nested);
void space_workflow_submit(enum command_palette_native_action action, uint64_t sid, char *text);
void space_workflow_handle_request(void *context);
void space_workflow_handle_space_created(uint64_t sid);
void space_workflow_destroy_snapshot(struct space_workflow_snapshot *snapshot);

#endif
