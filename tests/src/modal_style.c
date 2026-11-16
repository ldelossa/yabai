#include "../../src/modal_style.h"

TEST_FUNC(modal_style_width_metrics, {
    TEST_CHECK((int)modal_style_width_for(MODAL_STYLE_DEFAULT), 392);
    TEST_CHECK((int)modal_style_width_for(MODAL_STYLE_COMPACT), 320);
    TEST_CHECK((int)modal_style_row_height_for(MODAL_STYLE_DEFAULT), 30);
    TEST_CHECK((int)modal_style_row_height_for(MODAL_STYLE_COMPACT), 28);
})

TEST_FUNC(modal_style_list_height_bounds, {
    // Short list grows with its content and stays under the cap.
    TEST_CHECK((int)modal_style_list_height_for(MODAL_STYLE_DEFAULT, 6, 100, 600), 280);
    TEST_CHECK((int)modal_style_list_height_for(MODAL_STYLE_COMPACT, 6, 100, 600), 268);
    // Long list clamps to the 420-point cap.
    TEST_CHECK((int)modal_style_list_height_for(MODAL_STYLE_DEFAULT, 40, 100, 600), 420);
    // A tight available area clamps below the cap, leaving the requested margin.
    TEST_CHECK((int)modal_style_list_height_for(MODAL_STYLE_DEFAULT, 40, 100, 300), 268);
    // Zero and one rows shrink to chrome rather than collapsing to nothing.
    TEST_CHECK((int)modal_style_list_height_for(MODAL_STYLE_DEFAULT, 0, 100, 600), 100);
    TEST_CHECK((int)modal_style_list_height_for(MODAL_STYLE_DEFAULT, 1, 100, 600), 130);
})

TEST_FUNC(modal_style_state_wrappers, {
    modal_style_set(MODAL_STYLE_DEFAULT);
    TEST_CHECK(modal_style_current() == MODAL_STYLE_DEFAULT, true);
    TEST_CHECK((int)modal_style_panel_width(), 392);
    TEST_CHECK((int)modal_style_row_height(), 30);

    modal_style_set(MODAL_STYLE_COMPACT);
    TEST_CHECK(modal_style_current() == MODAL_STYLE_COMPACT, true);
    TEST_CHECK((int)modal_style_panel_width(), 320);
    TEST_CHECK((int)modal_style_row_height(), 28);

    modal_style_set(MODAL_STYLE_DEFAULT);
})
