TEST_FUNC(command_palette_action_lookup, {
    const struct command_palette_action *action = command_palette_find_action("space.layout");
    TEST_CHECK(action != NULL, true);
    TEST_CHECK(action && string_equals(action->domain, "space"), true);
    TEST_CHECK(action && string_equals(action->command, "--layout"), true);
    TEST_CHECK(action && action->argument_mode == COMMAND_PALETTE_ARGUMENT_REQUIRED, true);
    TEST_CHECK(command_palette_find_action("rule.add") == NULL, true);

    const struct command_palette_action *native_action = command_palette_find_action("space.choose");
    TEST_CHECK(native_action != NULL, true);
    TEST_CHECK(native_action && native_action->kind == COMMAND_PALETTE_ACTION_NATIVE, true);
    TEST_CHECK(native_action && native_action->native_action == COMMAND_PALETTE_NATIVE_SPACE_CHOOSE, true);
})

TEST_FUNC(command_palette_action_search, {
    const struct command_palette_action *action = command_palette_find_action("window.stack-selector-anchor");
    TEST_CHECK(command_palette_action_score(action, "ANCHOR") > 0, true);
    TEST_CHECK(command_palette_action_score(action, "window") > 0, true);
    TEST_CHECK(command_palette_action_score(action, "missing phrase") == 0, true);
    TEST_CHECK(command_palette_action_score(action, "") > 0, true);

    const struct command_palette_action *label_display = command_palette_find_action("display.label");
    const struct command_palette_action *set_layout = command_palette_find_action("space.layout");
    TEST_CHECK(command_palette_action_score(label_display, "set") == 0, true);
    TEST_CHECK(command_palette_action_score(set_layout, "set") > command_palette_action_score(label_display, "set"), true);
})

TEST_FUNC(command_palette_message_construction, {
    const struct command_palette_action *action = command_palette_find_action("space.label");
    int message_length = 0;
    char *message = command_palette_build_message(action, "Deep Work", &message_length);
    char *cursor = message;
    struct token domain = get_token(&cursor);
    struct token command = get_token(&cursor);
    struct token argument = get_token(&cursor);
    struct token terminator = get_token(&cursor);

    TEST_CHECK(message != NULL, true);
    TEST_CHECK(message_length > 0, true);
    TEST_CHECK(token_equals(domain, "space"), true);
    TEST_CHECK(token_equals(command, "--label"), true);
    TEST_CHECK(token_equals(argument, "Deep Work"), true);
    TEST_CHECK(token_is_valid(terminator), false);
    free(message);
})

TEST_FUNC(command_palette_catalog_integrity, {
    TEST_CHECK(g_command_palette_action_count > 0, true);
    for (int i = 0; i < g_command_palette_action_count; ++i) {
        const struct command_palette_action *action = &g_command_palette_actions[i];
        TEST_CHECK(action->identifier != NULL, true);
        TEST_CHECK(action->title != NULL, true);
        TEST_CHECK(action->category != NULL, true);
        if (action->kind == COMMAND_PALETTE_ACTION_IPC) {
            TEST_CHECK(action->domain != NULL, true);
            TEST_CHECK(action->command != NULL, true);
            TEST_CHECK(action->native_action == COMMAND_PALETTE_NATIVE_NONE, true);
            TEST_CHECK(!string_equals(action->domain, "rule"), true);
            TEST_CHECK(!string_equals(action->domain, "signal"), true);
            TEST_CHECK(!string_equals(action->domain, "query"), true);
        } else {
            TEST_CHECK(action->domain == NULL, true);
            TEST_CHECK(action->command == NULL, true);
            TEST_CHECK(action->native_action != COMMAND_PALETTE_NATIVE_NONE, true);
        }

        for (int j = i + 1; j < g_command_palette_action_count; ++j) {
            TEST_CHECK(!string_equals(action->identifier, g_command_palette_actions[j].identifier), true);
        }
    }
})

TEST_FUNC(space_workflow_layout_cycle, {
    TEST_CHECK(space_workflow_next_layout(VIEW_STACK) == VIEW_BSP, true);
    TEST_CHECK(space_workflow_next_layout(VIEW_BSP) == VIEW_FLOAT, true);
    TEST_CHECK(space_workflow_next_layout(VIEW_FLOAT) == VIEW_STACK, true);
})
