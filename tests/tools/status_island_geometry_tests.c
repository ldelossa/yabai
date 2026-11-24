#include "../../src/status_island_geometry.h"
#include <math.h>
#include <stdio.h>
#include <stdlib.h>

static int g_cases = 0;
static int g_failed = 0;

#define CHECK(cond, msg)                                                  \
    do {                                                                  \
        g_cases++;                                                        \
        if (!(cond)) {                                                    \
            g_failed++;                                                   \
            printf("FAIL %s:%d: %s\n", __FILE__, __LINE__, msg);          \
        }                                                                 \
    } while (0)

static bool nearly(double a, double b)
{
    return fabs(a - b) < 0.0001;
}

// Historical reproduction: a 450x60 shadow-expanded panel (Cocoa origin y up)
// with 28pt margins around a 394x32 visible surface.
static status_island_geometry historical(void)
{
    status_island_geometry g = {
        .shadow_margin = 28.0,
        .island_height = 30.0,
        .corner_radius = 15.0,
        .layout_wing_width = 100.0,
        .notch_width = 186.0,
        .notch_height = 32.0,
        .notch_center_x = 755.0,
        .screen_top_y = 982.0,
        .workspace_wing_width = 108.0,
        .collapsed = false,
    };
    return g;
}

static void test_historical_frames(void)
{
    status_island_geometry g = historical();

    CGRect shadow = status_island_shadow_frame(g);
    CHECK(nearly(shadow.origin.x, 526.0), "historical shadow x");
    CHECK(nearly(shadow.origin.y, 922.0), "historical shadow y (Cocoa)");
    CHECK(nearly(shadow.size.width, 450.0), "historical shadow width");
    CHECK(nearly(shadow.size.height, 60.0), "historical shadow height");

    CGRect visible = status_island_visible_frame(g);
    CHECK(nearly(visible.origin.x, 554.0), "historical visible x");
    CHECK(nearly(visible.origin.y, 950.0), "historical visible y (Cocoa)");
    CHECK(nearly(visible.size.width, 394.0), "historical visible width");
    CHECK(nearly(visible.size.height, 32.0), "historical visible height");
}

static void test_historical_recorded_click(void)
{
    status_island_geometry g = historical();
    CGPoint p = CGPointMake(544.625, 925.3047);

    // The recorded failing click is inside the shadow frame but outside the
    // visible surface (left/bottom margin). It must not be treated as island
    // input and, below the band, must not trigger collapse either.
    CHECK(status_island_point_in_shadow_frame(p, g), "recorded click in shadow frame");
    CHECK(!status_island_point_in_visible_surface(p, g), "recorded click outside visible surface");
    CHECK(!status_island_should_collapse_for_point(p, g), "recorded below-band click does not collapse");
}

static void test_margins_are_click_through(void)
{
    status_island_geometry g = historical();
    CGRect visible = status_island_visible_frame(g);

    CGPoint left = CGPointMake(visible.origin.x - 1.0, CGRectGetMidY(visible));
    CGPoint right = CGPointMake(visible.origin.x + visible.size.width + 1.0, CGRectGetMidY(visible));
    CGPoint bottom = CGPointMake(CGRectGetMidX(visible), visible.origin.y - 1.0);
    CGPoint interior = CGPointMake(CGRectGetMidX(visible), CGRectGetMidY(visible));

    CHECK(!status_island_point_in_visible_surface(left, g), "left margin outside visible");
    CHECK(!status_island_point_in_visible_surface(right, g), "right margin outside visible");
    CHECK(!status_island_point_in_visible_surface(bottom, g), "bottom margin outside visible");
    CHECK(status_island_point_in_visible_surface(interior, g), "interior inside visible");
    CHECK(status_island_point_in_shadow_frame(left, g), "left margin inside legacy shadow frame");
    CHECK(status_island_point_in_shadow_frame(right, g), "right margin inside legacy shadow frame");
    CHECK(status_island_point_in_shadow_frame(bottom, g), "bottom margin inside legacy shadow frame");
}

static void test_rounded_bottom_cutouts(void)
{
    status_island_geometry g = historical();
    CGRect visible = status_island_visible_frame(g);

    // Bottom corners are rounded; the diagonal just outside the 15pt arc is
    // transparent and must not count as visible surface.
    CGPoint bottom_left_diagonal = CGPointMake(visible.origin.x + 4.0, visible.origin.y + 4.0);
    CGPoint bottom_right_diagonal = CGPointMake(visible.origin.x + visible.size.width - 4.0, visible.origin.y + 4.0);
    CGPoint bottom_center = CGPointMake(CGRectGetMidX(visible), visible.origin.y + 1.0);
    CGPoint top_corner = CGPointMake(visible.origin.x + 1.0, visible.origin.y + visible.size.height - 1.0);

    CHECK(!status_island_point_in_visible_surface(bottom_left_diagonal, g), "bottom-left rounded cutout excluded");
    CHECK(!status_island_point_in_visible_surface(bottom_right_diagonal, g), "bottom-right rounded cutout excluded");
    CHECK(status_island_point_in_visible_surface(bottom_center, g), "bottom edge center is inside");
    CHECK(status_island_point_in_visible_surface(top_corner, g), "top corner is inside");
}

static void test_visible_edge_collapse(void)
{
    status_island_geometry g = historical();
    CGRect visible = status_island_visible_frame(g);
    double band_mid_y = visible.origin.y + visible.size.height / 2.0;

    CGPoint just_inside_left = CGPointMake(visible.origin.x + 0.5, band_mid_y);
    CGPoint just_outside_left = CGPointMake(visible.origin.x - 0.5, band_mid_y);
    CGPoint just_inside_right = CGPointMake(visible.origin.x + visible.size.width - 0.5, band_mid_y);
    CGPoint just_outside_right = CGPointMake(visible.origin.x + visible.size.width + 0.5, band_mid_y);

    CHECK(status_island_should_collapse_for_point(just_outside_left, g), "collapse just left of visible edge");
    CHECK(status_island_should_collapse_for_point(just_outside_right, g), "collapse just right of visible edge");
    CHECK(!status_island_should_collapse_for_point(just_inside_left, g), "no collapse just inside left edge");
    CHECK(!status_island_should_collapse_for_point(just_inside_right, g), "no collapse just inside right edge");

    // No shadow-width dead zone: the old shadow margin begins 28pt away and
    // must already be a collapse, not a place where the island stays expanded.
    CGPoint old_dead_zone_left = CGPointMake(visible.origin.x - 27.0, band_mid_y);
    CGPoint old_dead_zone_right = CGPointMake(visible.origin.x + visible.size.width + 27.0, band_mid_y);
    CHECK(status_island_should_collapse_for_point(old_dead_zone_left, g), "left margin collapses immediately");
    CHECK(status_island_should_collapse_for_point(old_dead_zone_right, g), "right margin collapses immediately");
}

static void test_below_band_preserves_behavior(void)
{
    status_island_geometry g = historical();
    CGRect visible = status_island_visible_frame(g);
    CGPoint below = CGPointMake(CGRectGetMidX(visible), visible.origin.y - 2.0);

    CHECK(status_island_point_in_shadow_frame(below, g), "below point still in legacy shadow frame");
    CHECK(!status_island_point_in_top_band(below, g), "below point is outside the top band");
    CHECK(!status_island_should_collapse_for_point(below, g), "below band never collapses from geometry alone");
}

static void test_zero_notch(void)
{
    status_island_geometry g = historical();
    g.notch_width = 0.0;
    g.notch_center_x = 1000.0;

    CGRect visible = status_island_visible_frame(g);
    CHECK(nearly(visible.size.width, 108.0 + 0.0 + 100.0), "zero-notch visible width collapses to wings");
    CGPoint interior = CGPointMake(CGRectGetMidX(visible), CGRectGetMidY(visible));
    CGPoint outside = CGPointMake(visible.origin.x - 1.0, CGRectGetMidY(visible));
    CHECK(status_island_point_in_visible_surface(interior, g), "zero-notch interior inside");
    CHECK(!status_island_point_in_visible_surface(outside, g), "zero-notch outside visible");
    CHECK(status_island_should_collapse_for_point(outside, g), "zero-notch outside collapses in band");
}

static void test_display_origin_variations(void)
{
    // A display positioned to the left of, and above, the main display keeps
    // its own screen_top_y; geometry must not assume the main-screen origin.
    status_island_geometry g = historical();
    g.screen_top_y = 2098.0;
    g.notch_center_x = -320.0;
    g.notch_width = 0.0;

    CGRect visible = status_island_visible_frame(g);
    CHECK(nearly(visible.origin.y, 2098.0 - 32.0), "external display visible y");
    CGPoint outside = CGPointMake(visible.origin.x - 1.0, CGRectGetMidY(visible));
    CHECK(status_island_should_collapse_for_point(outside, g), "external display left edge collapses");
}

static void test_collapsed_visible_width(void)
{
    status_island_geometry g = historical();
    g.collapsed = true;
    CGRect visible = status_island_visible_frame(g);
    CHECK(nearly(visible.size.width, g.notch_width), "collapsed visible width is notch only");

    // Reentering the collapsed notch expands rather than collapsing.
    CGPoint center = CGPointMake(CGRectGetMidX(visible), CGRectGetMidY(visible));
    CHECK(!status_island_should_collapse_for_point(center, g), "reentry into collapsed notch stays expanded");
}

int main(void)
{
    test_historical_frames();
    test_historical_recorded_click();
    test_margins_are_click_through();
    test_rounded_bottom_cutouts();
    test_visible_edge_collapse();
    test_below_band_preserves_behavior();
    test_zero_notch();
    test_display_origin_variations();
    test_collapsed_visible_width();

    printf("PASS geometry: %d cases\n", g_cases);
    return g_failed == 0 ? EXIT_SUCCESS : EXIT_FAILURE;
}
