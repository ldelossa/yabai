#include "modal_style.h"

enum modal_style g_modal_style = MODAL_STYLE_DEFAULT;

enum modal_style modal_style_current(void)
{
    return g_modal_style;
}

void modal_style_set(enum modal_style style)
{
    g_modal_style = style;
}

CGFloat modal_style_panel_width(void)
{
    return modal_style_width_for(g_modal_style);
}

CGFloat modal_style_row_height(void)
{
    return modal_style_row_height_for(g_modal_style);
}

CGFloat modal_style_list_height(size_t count, CGFloat chrome_height, CGFloat available_height)
{
    return modal_style_list_height_for(g_modal_style, count, chrome_height, available_height);
}
