static void scratch_stack_test_add_member(struct scratchpad *scratchpad, struct window *window)
{
    struct scratchpad_member member = {
        .window = window,
        .restore_frame = window->frame,
    };
    scratchpad_initialize_frame(scratchpad, window->frame);
    buf_push(scratchpad->members, member);
    scratchpad_node_add_window(scratchpad, window);
}

TEST_FUNC(scratch_stack_frame_is_initialized_once, {
    struct scratchpad scratchpad = {0};
    struct window first = {0};
    struct window second = {0};
    first.id = 1;
    first.frame = CGRectMake(100, 200, 400, 900);
    second.id = 2;
    second.frame = CGRectMake(300, 400, 900, 400);

    scratch_stack_test_add_member(&scratchpad, &first);
    scratch_stack_test_add_member(&scratchpad, &second);

    TEST_CHECK((int)scratchpad.node.area.x, 100);
    TEST_CHECK((int)scratchpad.node.area.y, 200);
    TEST_CHECK((int)scratchpad.node.area.w, 400);
    TEST_CHECK((int)scratchpad.node.area.h, 900);
    TEST_CHECK((int)scratchpad.members[0].restore_frame.size.width, 400);
    TEST_CHECK((int)scratchpad.members[1].restore_frame.size.width, 900);

    buf_free(scratchpad.members);
})

TEST_FUNC(scratch_stack_tracks_membership_and_mru, {
    struct scratchpad scratchpad = {0};
    struct window first = {0};
    struct window second = {0};
    struct window third = {0};
    first.id = 1;
    first.frame = CGRectMake(0, 0, 400, 300);
    second.id = 2;
    second.frame = CGRectMake(0, 0, 500, 400);
    third.id = 3;
    third.frame = CGRectMake(0, 0, 600, 500);

    scratch_stack_test_add_member(&scratchpad, &first);
    scratch_stack_test_add_member(&scratchpad, &second);
    scratch_stack_test_add_member(&scratchpad, &third);

    TEST_CHECK(scratchpad.node.window_count, 3);
    TEST_CHECK(scratchpad.node.window_list[0], 1);
    TEST_CHECK(scratchpad.node.window_list[1], 2);
    TEST_CHECK(scratchpad.node.window_list[2], 3);
    TEST_CHECK(scratchpad.node.window_order[0], 3);
    TEST_CHECK(scratchpad.node.window_order[1], 2);
    TEST_CHECK(scratchpad.node.window_order[2], 1);

    scratchpad_update_order(&scratchpad, &first);
    TEST_CHECK(scratchpad.node.window_order[0], 1);
    TEST_CHECK(scratchpad.node.window_order[1], 3);
    TEST_CHECK(scratchpad.node.window_order[2], 2);

    buf_free(scratchpad.members);
})

TEST_FUNC(scratch_stack_lookup_by_label, {
    struct window_manager wm = {0};
    struct scratchpad notes = { .label = "notes" };
    struct scratchpad terminals = { .label = "terminals" };
    buf_push(wm.scratchpads, notes);
    buf_push(wm.scratchpads, terminals);

    TEST_CHECK(window_manager_find_scratchpad_by_label(&wm, "notes") == &wm.scratchpads[0], true);
    TEST_CHECK(window_manager_find_scratchpad_by_label(&wm, "terminals") == &wm.scratchpads[1], true);
    TEST_CHECK(window_manager_find_scratchpad_by_label(&wm, "missing") == NULL, true);
    TEST_CHECK(window_manager_find_scratchpad_by_label(&wm, NULL) == NULL, true);

    struct window window = { .scratchpad = "terminals" };
    TEST_CHECK(window_manager_find_scratchpad_for_window(&wm, &window) == &wm.scratchpads[1], true);
    TEST_CHECK(window_manager_find_scratchpad_for_window(&wm, NULL) == NULL, true);

    buf_free(wm.scratchpads);
})

TEST_FUNC(scratch_stack_removal_preserves_frame, {
    struct scratchpad scratchpad = {0};
    struct window first = {0};
    struct window second = {0};
    first.id = 1;
    first.frame = CGRectMake(20, 30, 1000, 800);
    second.id = 2;
    second.frame = CGRectMake(20, 30, 600, 500);

    scratch_stack_test_add_member(&scratchpad, &first);
    scratch_stack_test_add_member(&scratchpad, &second);

    scratchpad_node_remove_window(&scratchpad, &first);
    buf_del(scratchpad.members, 0);

    TEST_CHECK(scratchpad.node.window_count, 1);
    TEST_CHECK(scratchpad.node.window_list[0], 2);
    TEST_CHECK(scratchpad.node.window_order[0], 2);
    TEST_CHECK((int)scratchpad.node.area.w, 1000);
    TEST_CHECK((int)scratchpad.node.area.h, 800);
    TEST_CHECK((int)scratchpad.members[0].restore_frame.size.width, 600);
    TEST_CHECK((int)scratchpad.members[0].restore_frame.size.height, 500);

    scratchpad_node_remove_window(&scratchpad, &second);
    buf_del(scratchpad.members, 0);
    TEST_CHECK(scratchpad.node.window_count, 0);
    TEST_CHECK(buf_len(scratchpad.members), 0);

    buf_free(scratchpad.members);
})
