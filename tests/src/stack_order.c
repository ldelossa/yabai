TEST_FUNC(window_node_reorder_preserves_order, {
    struct window_node node = {0};
    node.window_list[0] = 10;
    node.window_list[1] = 20;
    node.window_list[2] = 30;
    node.window_list[3] = 40;
    node.window_count = 4;
    node.window_order[0] = 40;
    node.window_order[1] = 30;
    node.window_order[2] = 20;
    node.window_order[3] = 10;

    window_node_reorder_window(&node, 10, 2);
    TEST_CHECK(node.window_list[0], 20);
    TEST_CHECK(node.window_list[1], 30);
    TEST_CHECK(node.window_list[2], 10);
    TEST_CHECK(node.window_list[3], 40);

    TEST_CHECK(node.window_order[0], 40);
    TEST_CHECK(node.window_order[1], 30);
    TEST_CHECK(node.window_order[2], 20);
    TEST_CHECK(node.window_order[3], 10);

    window_node_reorder_window(&node, 40, 0);
    TEST_CHECK(node.window_list[0], 40);
    TEST_CHECK(node.window_list[1], 20);
    TEST_CHECK(node.window_list[2], 30);
    TEST_CHECK(node.window_list[3], 10);

    window_node_reorder_window(&node, 30, 999);
    TEST_CHECK(node.window_list[3], 30);

    window_node_reorder_window(&node, 30, -5);
    TEST_CHECK(node.window_list[0], 30);
})
