#ifndef SA_DOCK_27_3_H
#define SA_DOCK_27_3_H

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <string.h>
#include <uuid/uuid.h>

// Each row is statically validated for one build and slice, never future 27.x.
// Keep the original names for the independently validated Beta 1 profile.
#define DOCK_27_3_BUILD "26C5035r"
#define DOCK_27_3_UUID "13bbb2e6-602c-30d2-baaf-88643fffa590"
#define DOCK_27_3_SUBTYPE 0x80000002U
#define DOCK_27_3_DOCK_SPACES_OFFSET 0x2fcb8
#define DOCK_27_3_ADD_SPACE_OFFSET 0x196160
#define DOCK_27_3_REMOVE_SPACE_OFFSET 0x133fe0
#define DOCK_27_3_POINTER_SLOT_OFFSET 0x33afd0

#define DOCK_27_3_BETA2_BUILD "26C5047e"
#define DOCK_27_3_BETA2_UUID "82e3f5d1-8244-3768-9972-55a9e5410477"
#define DOCK_27_3_BETA2_SUBTYPE 0x80000002U
#define DOCK_27_3_BETA2_DOCK_SPACES_OFFSET 0x2fcb8
#define DOCK_27_3_BETA2_ADD_SPACE_OFFSET 0x1969e8
#define DOCK_27_3_BETA2_REMOVE_SPACE_OFFSET 0x13458c
#define DOCK_27_3_BETA2_POINTER_SLOT_OFFSET 0x33b080

struct sa_dock_27_3_profile
{
    const char *build;
    const char *uuid;
    uint32_t subtype;
    uint64_t dock_spaces_offset;
    uint64_t add_space_offset;
    uint64_t remove_space_offset;
    uint64_t pointer_slot_offset;
};

static const struct sa_dock_27_3_profile sa_dock_27_3_profiles[] = {
    {
        DOCK_27_3_BUILD, DOCK_27_3_UUID, DOCK_27_3_SUBTYPE,
        DOCK_27_3_DOCK_SPACES_OFFSET, DOCK_27_3_ADD_SPACE_OFFSET,
        DOCK_27_3_REMOVE_SPACE_OFFSET, DOCK_27_3_POINTER_SLOT_OFFSET,
    },
    {
        DOCK_27_3_BETA2_BUILD, DOCK_27_3_BETA2_UUID, DOCK_27_3_BETA2_SUBTYPE,
        DOCK_27_3_BETA2_DOCK_SPACES_OFFSET, DOCK_27_3_BETA2_ADD_SPACE_OFFSET,
        DOCK_27_3_BETA2_REMOVE_SPACE_OFFSET, DOCK_27_3_BETA2_POINTER_SLOT_OFFSET,
    },
};

static inline const struct sa_dock_27_3_profile *sa_dock_27_3_profile_for(int major, int minor,
    uint32_t subtype, const char *build, const unsigned char *uuid)
{
    if (major != 27 || minor != 3 || !build || !uuid) return NULL;
    const struct sa_dock_27_3_profile *matched = NULL;
    for (size_t i = 0; i < sizeof(sa_dock_27_3_profiles) / sizeof(sa_dock_27_3_profiles[0]); ++i) {
        const struct sa_dock_27_3_profile *profile = &sa_dock_27_3_profiles[i];
        uuid_t expected;
        if (subtype != profile->subtype || strcmp(build, profile->build) ||
            uuid_parse(profile->uuid, expected) || memcmp(uuid, expected, sizeof(expected))) continue;
        if (matched) return NULL; // Ambiguous profile definitions must also fail closed.
        matched = profile;
    }
    return matched;
}

static inline bool sa_dock_27_3_matches(int major, int minor, uint32_t subtype, const char *build, const unsigned char *uuid)
{
    return sa_dock_27_3_profile_for(major, minor, subtype, build, uuid) != NULL;
}

#endif
