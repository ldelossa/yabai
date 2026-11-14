static uint32_t test_sa_attributes;
static bool test_sa_query_available;
static bool test_sa_query_version_match;
static int test_sa_query_count;

static bool test_sa_query(char *version, uint32_t *attributes)
{
    ++test_sa_query_count;
    if (!test_sa_query_available) return false;
    strcpy(version, test_sa_query_version_match ? OSAX_VERSION : "outdated");
    *attributes = test_sa_attributes;
    return true;
}

TEST_FUNC(sa_handshake_framing, {
    char bytes[128] = {0};
    uint32_t attributes = 0x0d;
    size_t version_length = strlen(OSAX_VERSION);
    memcpy(bytes, OSAX_VERSION, version_length);
    memcpy(bytes + version_length + 1, &attributes, sizeof(attributes));
    size_t complete_length = version_length + 1 + sizeof(attributes);
    struct sa_handshake handshake = {0};
    for (size_t i = 0; i < complete_length; ++i) {
        TEST_CHECK(sa_decode_handshake(bytes, i, &handshake), SA_HANDSHAKE_INCOMPLETE);
    }
    TEST_CHECK(sa_decode_handshake(bytes, complete_length, &handshake), SA_HANDSHAKE_COMPLETE);
    TEST_CHECK(strcmp(handshake.version, OSAX_VERSION), 0);
    TEST_CHECK(handshake.attributes, 0x0d);
    TEST_CHECK(sa_decode_handshake("\0", 1, &handshake), SA_HANDSHAKE_INVALID);
    memset(bytes, 'a', SA_HANDSHAKE_VERSION_MAX);
    TEST_CHECK(sa_decode_handshake(bytes, SA_HANDSHAKE_VERSION_MAX, &handshake), SA_HANDSHAKE_INVALID);
})

TEST_FUNC(sa_capability_preflight, {
    test_sa_query_count = 0;
    test_sa_query_available = true;
    test_sa_query_version_match = true;
    test_sa_attributes = 0;
    TEST_CHECK(scripting_addition_preflight(sa_required_attributes(SA_OPCODE_SPACE_CREATE), test_sa_query), false);
    TEST_CHECK(g_sa_error, SA_ERROR_CAPABILITY);
    TEST_CHECK(g_sa_missing_attributes, OSAX_ATTRIB_DOCK_SPACES | OSAX_ATTRIB_ADD_SPACE);
    TEST_CHECK(strstr(scripting_addition_error_message(), "capabilities") != NULL, true);

    // Partial support must be useful: missing movement/focus/animation does not block creation.
    test_sa_attributes = OSAX_ATTRIB_DOCK_SPACES | OSAX_ATTRIB_ADD_SPACE | OSAX_ATTRIB_REM_SPACE;
    TEST_CHECK(scripting_addition_preflight(sa_required_attributes(SA_OPCODE_SPACE_CREATE), test_sa_query), true);
    TEST_CHECK(scripting_addition_preflight(sa_required_attributes(SA_OPCODE_SPACE_DESTROY), test_sa_query), true);
    TEST_CHECK(scripting_addition_preflight(sa_required_attributes(SA_OPCODE_SPACE_FOCUS), test_sa_query), true);
    TEST_CHECK(scripting_addition_preflight(sa_required_attributes(SA_OPCODE_SPACE_MOVE), test_sa_query), false);
    TEST_CHECK(g_sa_missing_attributes, OSAX_ATTRIB_DPPM | OSAX_ATTRIB_MOV_SPACE);
    TEST_CHECK(scripting_addition_preflight(sa_required_attributes(SA_OPCODE_WINDOW_FOCUS), test_sa_query), false);
    int queries = test_sa_query_count;
    TEST_CHECK(scripting_addition_preflight(sa_required_attributes(SA_OPCODE_WINDOW_OPACITY), test_sa_query), true);
    TEST_CHECK(scripting_addition_preflight(sa_required_attributes(SA_OPCODE_WINDOW_ORDER), test_sa_query), true);
    TEST_CHECK(test_sa_query_count, queries);

    // A restarted Dock can return different flags; no cached success may survive it.
    test_sa_attributes = 0;
    TEST_CHECK(scripting_addition_preflight(sa_required_attributes(SA_OPCODE_SPACE_CREATE), test_sa_query), false);
    TEST_CHECK(test_sa_query_count, queries + 1);
    test_sa_query_version_match = false;
    TEST_CHECK(scripting_addition_preflight(OSAX_ATTRIB_DOCK_SPACES, test_sa_query), false);
    TEST_CHECK(g_sa_error, SA_ERROR_VERSION);
    test_sa_query_available = false;
    TEST_CHECK(scripting_addition_preflight(OSAX_ATTRIB_DOCK_SPACES, test_sa_query), false);
    TEST_CHECK(g_sa_error, SA_ERROR_CONNECTION);
    g_sa_error = SA_ERROR_NONE;
})

TEST_FUNC(sa_handshake_socket_errors, {
    int fds[2];
    int opened = socketpair(AF_UNIX, SOCK_STREAM, 0, fds);
    TEST_CHECK(opened, 0);
    if (opened == 0) {
        const char partial[] = "2.1";
        TEST_CHECK((int)write(fds[1], partial, sizeof(partial) - 1), (int)sizeof(partial) - 1);
        close(fds[1]);
        struct sa_handshake handshake;
        g_sa_error = SA_ERROR_NONE;
        TEST_CHECK(scripting_addition_read_handshake(fds[0], scripting_addition_now_ns() + 1000000000ULL, &handshake), false);
        TEST_CHECK(g_sa_error, SA_ERROR_HANDSHAKE);
        close(fds[0]);
    }
    opened = socketpair(AF_UNIX, SOCK_STREAM, 0, fds);
    TEST_CHECK(opened, 0);
    if (opened == 0) {
        char bytes[128] = OSAX_VERSION;
        uint32_t attributes = 0x0d;
        size_t length = strlen(OSAX_VERSION) + 1;
        memcpy(bytes + length, &attributes, sizeof(attributes));
        for (size_t i = 0; i < length + sizeof(attributes); ++i) {
            TEST_CHECK((int)write(fds[1], bytes + i, 1), 1);
        }
        struct sa_handshake handshake;
        TEST_CHECK(scripting_addition_read_handshake(fds[0], scripting_addition_now_ns() + 1000000000ULL, &handshake), true);
        TEST_CHECK(handshake.attributes, 0x0d);
        // A deadline already reached must not block, even if the peer remains open.
        TEST_CHECK(scripting_addition_read_handshake(fds[0], scripting_addition_now_ns(), &handshake), false);
        close(fds[0]);
        close(fds[1]);
    }
    g_sa_error = SA_ERROR_NONE;
})

TEST_FUNC(space_workflow_create_lifecycle, {
    TEST_CHECK(g_space_workflow_pending_create.active, false);
    TEST_CHECK(space_workflow_reserve_create(42, "first"), true);
    uint64_t first_generation = g_space_workflow_pending_create.generation;
    TEST_CHECK(space_workflow_reserve_create(42, "duplicate"), false);
    TEST_CHECK(space_workflow_expire_create(first_generation - 1), false);
    TEST_CHECK(g_space_workflow_pending_create.active, true);

    // Same cleanup used by immediate preflight failure: a retry is possible immediately.
    space_workflow_clear_pending_create();
    TEST_CHECK(space_workflow_reserve_create(42, "retry"), true);
    uint64_t retry_generation = g_space_workflow_pending_create.generation;
    TEST_CHECK(retry_generation > first_generation, true);
    TEST_CHECK(space_workflow_expire_create(first_generation), false);
    char *label = NULL;
    TEST_CHECK(space_workflow_take_created_label(99, &label), false);
    TEST_CHECK(g_space_workflow_pending_create.active, true);
    TEST_CHECK(space_workflow_take_created_label(42, &label), true);
    TEST_CHECK(label && strcmp(label, "retry") == 0, true);
    TEST_CHECK(g_space_workflow_pending_create.active, false);
    TEST_CHECK(space_workflow_expire_create(retry_generation), false);
    free(label);

    TEST_CHECK(space_workflow_reserve_create(42, "timeout"), true);
    TEST_CHECK(space_workflow_expire_create(g_space_workflow_pending_create.generation), true);
    TEST_CHECK(g_space_workflow_pending_create.label == NULL, true);
    TEST_CHECK(g_space_workflow_pending_create.active, false);
})
