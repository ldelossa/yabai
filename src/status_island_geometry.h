#ifndef STATUS_ISLAND_GEOMETRY_H
#define STATUS_ISLAND_GEOMETRY_H

#include <CoreGraphics/CoreGraphics.h>
#include <math.h>
#include <stdbool.h>

// Shared, dependency-light geometry for the per-display status island and its
// flyouts. All coordinates are Cocoa screen coordinates (origin bottom-left,
// y increases upward), matching NSPanel frames and NSEvent.mouseLocation.
//
// Production keeps the visual shadow, but shadow margins must never own clicks
// or count as hovering the island. This helper provides the two geometries
// separately: the visible surface and the legacy shadow-expanded panel frame.

typedef struct {
    double shadow_margin;
    double island_height;         // minimum visible island height
    double corner_radius;
    double layout_wing_width;     // visible width of the layout (right) wing
    double notch_width;           // 0 when the display has no notch
    double notch_height;          // safeAreaInsets.top, at least island_height
    double notch_center_x;        // screen-space center of the notch
    double screen_top_y;          // screen.frame.maxY in Cocoa coordinates
    double workspace_wing_width;  // visible width of the workspace (left) wing
    bool collapsed;               // wings hidden
} status_island_geometry;

static inline double status_island_left_wing_width(status_island_geometry g)
{
    return g.collapsed ? 0.0 : g.workspace_wing_width;
}

static inline double status_island_right_wing_width(status_island_geometry g)
{
    return g.collapsed ? 0.0 : g.layout_wing_width;
}

static inline double status_island_visible_width(status_island_geometry g)
{
    return status_island_left_wing_width(g) + g.notch_width + status_island_right_wing_width(g);
}

// Visible surface frame in screen coordinates. The top edge sits flush under
// the screen top; the bottom corners are rounded but this frame is the bounding
// rect used for fast rejection.
static inline CGRect status_island_visible_frame(status_island_geometry g)
{
    double left_wing = status_island_left_wing_width(g);
    double notch_left = g.notch_center_x - g.notch_width / 2.0;
    return CGRectMake(notch_left - left_wing,
                      g.screen_top_y - g.notch_height,
                      status_island_visible_width(g),
                      g.notch_height);
}

// Legacy shadow-expanded panel frame. Retained only to reproduce current
// behavior and to prove that invisible margins are excluded from input.
static inline CGRect status_island_shadow_frame(status_island_geometry g)
{
    CGRect visible = status_island_visible_frame(g);
    return CGRectMake(visible.origin.x - g.shadow_margin,
                      visible.origin.y - g.shadow_margin,
                      visible.size.width + 2.0 * g.shadow_margin,
                      visible.size.height + g.shadow_margin);
}

// Bottom-rounded visible path in the surface's own coordinate space
// (origin bottom-left). Matches the historical mask/shadow path so rounded
// transparent corners are never treated as input surface.
static inline CGPathRef status_island_visible_path(status_island_geometry g)
{
    CGFloat w = (CGFloat)status_island_visible_width(g);
    CGFloat h = (CGFloat)g.notch_height;
    CGFloat r = (CGFloat)(g.corner_radius < h ? g.corner_radius : h);
    CGMutablePathRef path = CGPathCreateMutable();
    if (w <= 0.0 || h <= 0.0 || r <= 0.0) {
        CGPathAddRect(path, NULL, CGRectMake(0, 0, w, h));
        return path;
    }

    CGPathMoveToPoint(path, NULL, 0, h);
    CGPathAddLineToPoint(path, NULL, w, h);
    CGPathAddLineToPoint(path, NULL, w, r);
    CGPathAddArc(path, NULL, w - r, r, r, 0.0, 3.0 * M_PI_2, true);
    CGPathAddLineToPoint(path, NULL, r, 0);
    CGPathAddArc(path, NULL, r, r, r, 3.0 * M_PI_2, M_PI, true);
    CGPathCloseSubpath(path);
    return path;
}

static inline bool status_island_point_in_visible_surface(CGPoint p, status_island_geometry g)
{
    CGRect visible = status_island_visible_frame(g);
    if (!CGRectContainsPoint(visible, p)) return false;

    CGPathRef path = status_island_visible_path(g);
    CGPoint local = CGPointMake(p.x - visible.origin.x, p.y - visible.origin.y);
    bool contained = CGPathContainsPoint(path, NULL, local, false);
    CGPathRelease(path);
    return contained;
}

static inline bool status_island_point_in_shadow_frame(CGPoint p, status_island_geometry g)
{
    return CGRectContainsPoint(status_island_shadow_frame(g), p);
}

// The collapse band is the same vertical strip the island occupies, from its
// top edge down to its bottom edge. Nothing changes below this band.
static inline bool status_island_point_in_top_band(CGPoint p, status_island_geometry g)
{
    return p.y >= g.screen_top_y - g.notch_height && p.y <= g.screen_top_y;
}

// The screen's top row is a hover-only continuation of the visible island.
// Cocoa's maximum-Y boundary is not part of CGRectContainsPoint, so a cursor
// thrown to that edge would otherwise collapse the island above either wing.
// This does not expand any panel's clickable frame or the horizontal hover span.
static inline bool status_island_point_in_top_edge_hover(CGPoint p, status_island_geometry g)
{
    CGRect visible = status_island_visible_frame(g);
    return p.x >= CGRectGetMinX(visible) && p.x < CGRectGetMaxX(visible) &&
           p.y >= g.screen_top_y - 1.0 && p.y <= g.screen_top_y;
}

// Collapse at the visible left/right edge: inside the top strip but outside
// both the visible surface and its top-edge hover continuation. Callers still
// apply on-display and open-menu protection.
static inline bool status_island_should_collapse_for_point(CGPoint p, status_island_geometry g)
{
    return status_island_point_in_top_band(p, g) &&
           !status_island_point_in_visible_surface(p, g) &&
           !status_island_point_in_top_edge_hover(p, g);
}

#endif /* STATUS_ISLAND_GEOMETRY_H */
