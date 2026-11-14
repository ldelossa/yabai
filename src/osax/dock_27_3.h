#ifndef SA_DOCK_27_3_H
#define SA_DOCK_27_3_H

#include <stdbool.h>
#include <stdint.h>
#include <string.h>
#include <uuid/uuid.h>

// Static validation applies only to this build and slice, not all future 27.x releases.
#define DOCK_27_3_BUILD "26C5035r"
#define DOCK_27_3_UUID "13bbb2e6-602c-30d2-baaf-88643fffa590"
#define DOCK_27_3_SUBTYPE 0x80000002U
#define DOCK_27_3_DOCK_SPACES_OFFSET 0x2fcb8
#define DOCK_27_3_ADD_SPACE_OFFSET 0x196160
#define DOCK_27_3_REMOVE_SPACE_OFFSET 0x133fe0
#define DOCK_27_3_POINTER_SLOT_OFFSET 0x33afd0

static inline bool sa_dock_27_3_matches(int major, int minor, uint32_t subtype, const char *build, const unsigned char *uuid)
{
    uuid_t expected;
    return major == 27 && minor == 3 && subtype == DOCK_27_3_SUBTYPE && build && uuid &&
           strcmp(build, DOCK_27_3_BUILD) == 0 && uuid_parse(DOCK_27_3_UUID, expected) == 0 &&
           memcmp(uuid, expected, sizeof(expected)) == 0;
}

#endif
