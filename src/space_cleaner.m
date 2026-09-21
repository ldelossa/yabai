extern struct space_manager g_space_manager;
extern struct window_manager g_window_manager;

bool g_space_cleaner_enabled = false;

void space_cleaner_run(void)
{
    if (!g_space_cleaner_enabled) return;

    int display_count = 0;
    uint32_t *display_list = display_manager_active_display_list(&display_count);
    for (int display = 0; display < display_count; ++display) {
        uint32_t did = display_list[display];
        uint64_t visible_sid = display_space_id(did);
        int space_count = 0;
        uint64_t *space_list = display_space_list(did, &space_count);
        for (int i = 0; i < space_count; ++i) {
            uint64_t sid = space_list[i];
            if (!space_is_user(sid)) continue;
            if (sid == visible_sid) continue;

            int window_count = 0;
            table_for (struct window *window, g_window_manager.window, {
                if (space_manager_is_window_on_space(sid, window)) ++window_count;
            })
            if (window_count > 0) continue;

            space_manager_destroy_space(sid);
        }
    }
}
