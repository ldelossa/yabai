#ifndef STACK_SELECTOR_H
#define STACK_SELECTOR_H

extern bool g_stack_selector_enabled;
extern enum stack_selector_anchor g_stack_selector_default_anchor;
extern char *g_stack_selector_anchor_str[];

void stack_selector_set_enabled(bool enabled);
void stack_selector_set_default_anchor(enum stack_selector_anchor anchor);
void stack_selector_update_node(struct window_node *node);
void stack_selector_update_node_with_active_window(struct window_node *node, uint32_t window_id);
void stack_selector_update_all(void);
void stack_selector_hide_all(void);
void stack_selector_destroy_node(struct window_node *node);

#endif
