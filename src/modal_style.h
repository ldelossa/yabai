#ifndef MODAL_STYLE_H
#define MODAL_STYLE_H

#include <CoreGraphics/CoreGraphics.h>
#include <stddef.h>
#include <math.h>

// Single visual style for every transient surface (palette, island flyouts, and
// stack selector). `default` is the quiet list; `compact` is the tighter menu.
enum modal_style
{
    MODAL_STYLE_DEFAULT,
    MODAL_STYLE_COMPACT,
};

// Pure, testable metrics. Prefer these in tests so no runtime state is needed.
static inline CGFloat modal_style_width_for(enum modal_style style)
{
    return style == MODAL_STYLE_COMPACT ? 320.0f : 392.0f;
}

static inline CGFloat modal_style_row_height_for(enum modal_style style)
{
    return style == MODAL_STYLE_COMPACT ? 28.0f : 30.0f;
}

// Total panel height for a list of `count` rows plus fixed chrome, bounded by
// the 420-point cap and by `available_height` minus a margin. Short lists shrink
// to their content; long lists clamp and the body scrolls.
static inline CGFloat modal_style_list_height_for(enum modal_style style, size_t count, CGFloat chrome_height, CGFloat available_height)
{
    const CGFloat max_cap = 420.0f;
    const CGFloat margin = 32.0f;

    CGFloat content = (CGFloat)count * modal_style_row_height_for(style) + chrome_height;
    CGFloat available = available_height - margin;
    CGFloat cap = fmin(max_cap, available > 0.0f ? available : 0.0f);
    return fmin(content, cap);
}

// Rename has its own small footprint; other modal widths/heights stay unchanged.
struct modal_rename_layout {
    CGSize size;
    CGRect input, save, cancel, error;
};

static inline struct modal_rename_layout modal_style_rename_layout_for(enum modal_style style, CGFloat error_height, CGFloat available_height)
{
    int compact = style == MODAL_STYLE_COMPACT;
    CGFloat width = compact ? 288.0f : 320.0f;
    CGFloat base = compact ? 60.0f : 68.0f;
    CGFloat margin = compact ? 6.0f : 8.0f;
    CGFloat gap = compact ? 8.0f : 10.0f;
    CGFloat input = compact ? 26.0f : 28.0f;
    CGFloat button_width = compact ? 60.0f : 64.0f;
    CGFloat button_height = compact ? 22.0f : 24.0f;
    CGFloat action_height = 2 * button_height + 4.0f;
    // Keep the minimum interactive chrome usable. Normal Mac screen areas are
    // larger than this; long errors scroll within the remaining height budget.
    CGFloat cap = fmax(base, fmin(420.0f, available_height - 32.0f));
    CGFloat extra = error_height > 0 ? ceil(error_height) + 6.0f : 0;
    CGFloat height = fmin(base + extra, cap);
    CGFloat error = fmax(0, height - base - (error_height > 0 ? 6.0f : 0));
    CGFloat actions_y = margin + (error_height > 0 ? error + 6.0f : 0);
    struct modal_rename_layout layout;
    layout.size = CGSizeMake(width, height);
    layout.input = CGRectMake(margin, actions_y + (action_height - input) / 2,
                              width - 2 * margin - gap - button_width, input);
    layout.save = CGRectMake(width - margin - button_width, actions_y + button_height + 4.0f,
                             button_width, button_height);
    layout.cancel = CGRectMake(width - margin - button_width, actions_y, button_width, button_height);
    layout.error = CGRectMake(margin, margin, width - 2 * margin, error);
    return layout;
}

// Stateful wrappers backed by g_modal_style; defined in modal_style.c.
extern enum modal_style g_modal_style;

enum modal_style modal_style_current(void);
void modal_style_set(enum modal_style style);
CGFloat modal_style_panel_width(void);
CGFloat modal_style_row_height(void);
CGFloat modal_style_list_height(size_t count, CGFloat chrome_height, CGFloat available_height);

#endif
