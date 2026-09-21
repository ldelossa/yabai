#ifndef COMMAND_PALETTE_H
#define COMMAND_PALETTE_H

struct space_workflow_snapshot;

enum command_palette_argument_mode
{
    COMMAND_PALETTE_ARGUMENT_NONE,
    COMMAND_PALETTE_ARGUMENT_REQUIRED,
    COMMAND_PALETTE_ARGUMENT_OPTIONAL,
};

enum command_palette_action_kind
{
    COMMAND_PALETTE_ACTION_IPC,
    COMMAND_PALETTE_ACTION_NATIVE,
};

enum command_palette_native_action
{
    COMMAND_PALETTE_NATIVE_NONE,
    COMMAND_PALETTE_NATIVE_SPACE_CHOOSE,
    COMMAND_PALETTE_NATIVE_SPACE_RELABEL,
    COMMAND_PALETTE_NATIVE_SPACE_LAYOUT_CYCLE,
};

struct command_palette_action
{
    char *identifier;
    char *title;
    char *category;
    char *domain;
    char *command;
    char *syntax;
    char *description;
    enum command_palette_argument_mode argument_mode;
    enum command_palette_action_kind kind;
    enum command_palette_native_action native_action;
    bool destructive;
};

struct command_palette_execution_request
{
    const struct command_palette_action *action;
    char *argument;
    uint64_t sid;
    bool from_ui;
};

extern const struct command_palette_action g_command_palette_actions[];
extern const int g_command_palette_action_count;

const struct command_palette_action *command_palette_find_action(char *identifier);
int command_palette_action_score(const struct command_palette_action *action, char *query);
char *command_palette_build_message(const struct command_palette_action *action, char *argument, int *length);
void command_palette_handle_message(FILE *rsp, char *message);
void command_palette_show(void);
void command_palette_execute_request(void *context);
void command_palette_show_space_workflow(struct space_workflow_snapshot *snapshot);
void command_palette_show_space_result(char *message, bool success, bool close_panel);

#endif
