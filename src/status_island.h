#ifndef STATUS_ISLAND_H
#define STATUS_ISLAND_H

#include <stdbool.h>

struct space_workflow_snapshot;

enum status_island_workspace_order
{
    STATUS_ISLAND_ORDER_INDEX,
    STATUS_ISLAND_ORDER_ALPHABETICAL,
    STATUS_ISLAND_ORDER_CREATION,
};

extern enum status_island_workspace_order g_status_island_workspace_order;

bool status_island_is_enabled(void);
void status_island_set_enabled(bool enabled);
void status_island_set_workspace_order(enum status_island_workspace_order order);
void status_island_refresh(void);

#endif
