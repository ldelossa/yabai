#ifndef NATIVE_PALETTE_H
#define NATIVE_PALETTE_H

enum native_palette_row_visual_state
{
    NATIVE_PALETTE_ROW_NONE,
    NATIVE_PALETTE_ROW_HOVERED,
    NATIVE_PALETTE_ROW_SELECTED,
};

enum native_palette_item_kind
{
    NATIVE_PALETTE_ITEM_ACTION,
    NATIVE_PALETTE_ITEM_SPACE,
    NATIVE_PALETTE_ITEM_CREATE_SPACE,
};

enum native_palette_badge_style
{
    NATIVE_PALETTE_BADGE_NONE,
    NATIVE_PALETTE_BADGE_SELECTOR,
    NATIVE_PALETTE_BADGE_ENUM,
    NATIVE_PALETTE_BADGE_NATIVE,
    NATIVE_PALETTE_BADGE_TEXT,
};

@interface native_palette_item : NSObject {
    NSString *_title;
    NSString *_detail;
    NSString *_category;
    NSString *_symbolName;
    NSString *_badge;
    NSImage *_iconImage;
    enum native_palette_item_kind _kind;
    enum native_palette_badge_style _badgeStyle;
    void *_representedPointer;
    uint64_t _representedValue;
}
@property(copy) NSString *title;
@property(copy) NSString *detail;
@property(copy) NSString *category;
@property(copy) NSString *symbolName;
@property(copy) NSString *badge;
@property(retain) NSImage *iconImage;
@property(assign) enum native_palette_item_kind kind;
@property(assign) enum native_palette_badge_style badgeStyle;
@property(assign) void *representedPointer;
@property(assign) uint64_t representedValue;
+ (instancetype)itemWithTitle:(NSString *)title
                       detail:(NSString *)detail
                     category:(NSString *)category
                   symbolName:(NSString *)symbolName
                         kind:(enum native_palette_item_kind)kind;
@end

@interface native_palette_row : NSTableRowView {
    NSInteger _row;
    NSView *_highlightView;
    enum native_palette_row_visual_state _visualState;
}
@property(assign) NSInteger row;
- (void)setVisualState:(enum native_palette_row_visual_state)visualState;
@end

@interface native_palette_row_view : NSTableCellView {
    NSImageView *_iconView;
    NSTextField *_titleField;
    NSTextField *_detailField;
    NSTextField *_categoryField;
    NSTextField *_badgeField;
}
- (void)updateWithItem:(native_palette_item *)item;
@end

#endif
