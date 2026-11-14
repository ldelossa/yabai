#ifndef SA_PROTOCOL_H
#define SA_PROTOCOL_H

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <string.h>
#include "osax/common.h"

#define SA_HANDSHAKE_VERSION_MAX 64

struct sa_handshake
{
    char version[SA_HANDSHAKE_VERSION_MAX];
    uint32_t attributes;
};

enum sa_handshake_result
{
    SA_HANDSHAKE_INCOMPLETE,
    SA_HANDSHAKE_INVALID,
    SA_HANDSHAKE_COMPLETE,
};

// A response may arrive in several reads. Never inspect bytes beyond length.
static inline enum sa_handshake_result sa_decode_handshake(const char *bytes, size_t length, struct sa_handshake *result)
{
    const char *zero = memchr(bytes, '\0', length);
    if (!zero) return length >= SA_HANDSHAKE_VERSION_MAX ? SA_HANDSHAKE_INVALID : SA_HANDSHAKE_INCOMPLETE;

    size_t version_length = zero - bytes;
    if (!version_length || version_length >= sizeof(result->version)) return SA_HANDSHAKE_INVALID;
    if (length - version_length - 1 < sizeof(result->attributes)) return SA_HANDSHAKE_INCOMPLETE;

    memcpy(result->version, bytes, version_length);
    result->version[version_length] = '\0';
    memcpy(&result->attributes, zero + 1, sizeof(result->attributes));
    return SA_HANDSHAKE_COMPLETE;
}

static inline uint32_t sa_required_attributes(enum sa_opcode opcode)
{
    switch (opcode) {
    case SA_OPCODE_SPACE_CREATE: return OSAX_ATTRIB_DOCK_SPACES | OSAX_ATTRIB_ADD_SPACE;
    case SA_OPCODE_SPACE_DESTROY: return OSAX_ATTRIB_DOCK_SPACES | OSAX_ATTRIB_REM_SPACE;
    case SA_OPCODE_SPACE_FOCUS: return OSAX_ATTRIB_DOCK_SPACES;
    case SA_OPCODE_SPACE_MOVE: return OSAX_ATTRIB_DOCK_SPACES | OSAX_ATTRIB_DPPM | OSAX_ATTRIB_MOV_SPACE;
    case SA_OPCODE_WINDOW_FOCUS: return OSAX_ATTRIB_SET_WINDOW;
    default: return 0; // Direct SkyLight operations do not depend on pattern resolution.
    }
}

#endif
