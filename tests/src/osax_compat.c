#include "../../src/osax/pattern_scan.h"
#include "../../src/osax/dock_27_3.h"
#include "../../src/osax/space_compat.h"

@interface test_display_id_spaces : NSObject {
@public
    NSArray *_displaySpaces;
    id destination;
    uint32_t received_display;
}
- (uint32_t)displayIDForSpace:(id)space;
- (id)currentSpaceForDisplay:(uint32_t)display;
@end
@implementation test_display_id_spaces
- (uint32_t)displayIDForSpace:(id)space { return space == destination ? 123 : 0; }
- (id)currentSpaceForDisplay:(uint32_t)display { received_display = display; return destination; }
@end

@interface test_legacy_uuid_spaces : test_display_id_spaces {
@public
    CFStringRef received_uuid;
}
- (id)currentSpaceForDisplayUUID:(CFStringRef)uuid;
@end
@implementation test_legacy_uuid_spaces
- (id)currentSpaceForDisplayUUID:(CFStringRef)uuid { received_uuid = uuid; return destination; }
@end

TEST_FUNC(osax_pattern_bounds_and_uniqueness, {
    uint32_t words[8] = {0};
    uint8_t *bytes = (uint8_t *)words;
    const uint8_t *pattern = (const uint8_t *)"\x12\x34\x56\x78";
    memcpy(bytes + 4, pattern, 4);
    TEST_CHECK(sa_find_unique_pattern(bytes, sizeof(words), "12 34 56 78") == bytes + 4, true);
    TEST_CHECK(sa_find_unique_pattern(bytes, sizeof(words), "12 ?? ?8 78") == bytes + 4, true);
    TEST_CHECK(sa_find_unique_pattern(bytes, 7, "12 34 56 78") == NULL, true);
    TEST_CHECK(sa_find_unique_pattern(bytes, 8, "12 34 56 78") == bytes + 4, true);
    memcpy(bytes + 12, pattern, 4);
    TEST_CHECK(sa_find_unique_pattern(bytes, sizeof(words), "12 34 56 78") == NULL, true);
    TEST_CHECK(sa_find_unique_pattern(bytes, sizeof(words), "GG 34") == NULL, true);
    TEST_CHECK(sa_find_unique_pattern(bytes, sizeof(words), "") == NULL, true);
    TEST_CHECK(sa_find_unique_pattern(bytes, sizeof(words), "1") == NULL, true);
    memset(words, 0, sizeof(words));
    memcpy(bytes + 1, pattern, 4);
    TEST_CHECK(sa_find_unique_pattern(bytes, sizeof(words), "12 34 56 78") == NULL, true);
})

TEST_FUNC(osax_profile_and_pointer_decode, {
    uint32_t instructions[2];
    instructions[0] = 0xf0001848;
    instructions[1] = 0x913f4108;
    uint64_t target = 0;
    TEST_CHECK(sa_decode_adrp_add((uint8_t *)instructions, 0x10002fcb8, &target), true);
    TEST_CHECK(target == 0x10033afd0, true);
    instructions[0] = 0xf0ffffe8; // Negative page displacement must be sign-extended.
    instructions[1] = 0x91000108;
    TEST_CHECK(sa_decode_adrp_add((uint8_t *)instructions, 0x100020000, &target), true);
    TEST_CHECK(target == 0x10001f000, true);
    instructions[1] = 0x91000129;
    TEST_CHECK(sa_decode_adrp_add((uint8_t *)instructions, 0x100020000, &target), false);

    uuid_t uuid;
    uuid_parse(DOCK_27_3_UUID, uuid);
    TEST_CHECK(sa_dock_27_3_matches(27, 3, DOCK_27_3_SUBTYPE, DOCK_27_3_BUILD, uuid), true);
    TEST_CHECK(sa_dock_27_3_matches(27, 2, DOCK_27_3_SUBTYPE, DOCK_27_3_BUILD, uuid), false);
    TEST_CHECK(sa_dock_27_3_matches(28, 3, DOCK_27_3_SUBTYPE, DOCK_27_3_BUILD, uuid), false);
    TEST_CHECK(sa_dock_27_3_matches(27, 3, 0x8000000c, DOCK_27_3_BUILD, uuid), false);
    TEST_CHECK(sa_dock_27_3_matches(27, 3, DOCK_27_3_SUBTYPE, "unknown", uuid), false);
    uuid[0] ^= 1;
    TEST_CHECK(sa_dock_27_3_matches(27, 3, DOCK_27_3_SUBTYPE, DOCK_27_3_BUILD, uuid), false);
})

TEST_FUNC(osax_focus_list_ownership, {
    __block CFArrayRef held_source = NULL;
    __block CFArrayRef held_destination = NULL;
    __block bool callback_checked = false;
    @autoreleasepool {
        sa_with_space_lists(24, 36, ^(CFArrayRef source, CFArrayRef destination) {
            callback_checked = CFArrayGetCount(source) == 1 && CFArrayGetCount(destination) == 1;
            held_source = (CFArrayRef)CFRetain(source);
            held_destination = (CFArrayRef)CFRetain(destination);
        });
    }
    // With autoreleased literals plus an explicit release, these held objects die at
    // the pool drain despite our retain, reproducing the live Dock ownership failure.
    TEST_CHECK(callback_checked, true);
    TEST_CHECK((int)CFArrayGetCount(held_source), 1);
    TEST_CHECK((int)CFArrayGetCount(held_destination), 1);
    int64_t source_id = 0;
    int64_t destination_id = 0;
    CFNumberGetValue(CFArrayGetValueAtIndex(held_source, 0), kCFNumberSInt64Type, &source_id);
    CFNumberGetValue(CFArrayGetValueAtIndex(held_destination, 0), kCFNumberSInt64Type, &destination_id);
    TEST_CHECK((int)source_id, 24);
    TEST_CHECK((int)destination_id, 36);
    CFRelease(held_destination);
    CFRelease(held_source);
})

TEST_FUNC(osax_space_selector_and_storage_guards, {
    id destination = [[NSObject alloc] init];
    test_display_id_spaces *current = [[test_display_id_spaces alloc] init];
    current->destination = destination;
    TEST_CHECK(sa_current_space_for_display(current, true, CFSTR("display"), destination) == destination, true);
    TEST_CHECK(current->received_display, 123);
    current->received_display = 0;
    TEST_CHECK(sa_current_space_for_display(current, true, CFSTR("display"), nil) == nil, true);
    TEST_CHECK(current->received_display, 0);
    TEST_CHECK(sa_current_space_for_display(destination, true, CFSTR("display"), destination) == nil, true);
    TEST_CHECK(sa_current_space_for_display(current, true, NULL, destination) == nil, true);

    test_legacy_uuid_spaces *legacy = [[test_legacy_uuid_spaces alloc] init];
    legacy->destination = destination;
    TEST_CHECK(sa_current_space_for_display(legacy, true, CFSTR("legacy"), destination) == destination, true);
    TEST_CHECK(legacy->received_uuid == CFSTR("legacy"), true);
    TEST_CHECK(legacy->received_display, 0);

    TEST_CHECK(sa_get_object_ivar(nil, "_displaySpaces") == nil, true);
    TEST_CHECK(sa_get_object_ivar(destination, "_displaySpaces") == nil, true);
    TEST_CHECK(sa_display_spaces(current) == nil, true);
    NSArray *array = [[NSArray alloc] initWithArray:@[destination]];
    current->_displaySpaces = array;
    TEST_CHECK(sa_display_spaces(current) == array, true);
    current->_displaySpaces = (NSArray *)(uintptr_t)1;
    TEST_CHECK(sa_display_spaces(current) == nil, true);
    current->_displaySpaces = nil;
    [array release];
    [legacy release];
    [current release];
    [destination release];
})
