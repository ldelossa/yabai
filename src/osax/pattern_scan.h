#ifndef SA_PATTERN_SCAN_H
#define SA_PATTERN_SCAN_H

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <string.h>

// For the new profiled resolver only. Legacy OS paths retain their scanner.
static inline int sa_hex_digit(char c)
{
    if (c >= '0' && c <= '9') return c - '0';
    if (c >= 'A' && c <= 'F') return c - 'A' + 10;
    if (c >= 'a' && c <= 'f') return c - 'a' + 10;
    return -1;
}

static inline const uint8_t *sa_find_unique_pattern(const uint8_t *start, size_t size, const char *pattern)
{
    uint8_t bytes[256], wildcard[256];
    size_t count = 0;
    if (!start || !pattern) return NULL;
    while (*pattern) {
        if (count == sizeof(bytes) || !pattern[1]) return NULL;
        wildcard[count] = pattern[0] == '?';
        if (!wildcard[count]) {
            int high = sa_hex_digit(pattern[0]), low = sa_hex_digit(pattern[1]);
            if (high < 0 || low < 0) return NULL;
            bytes[count] = (high << 4) | low;
        }
        ++count;
        pattern += 2;
        if (*pattern && *pattern++ != ' ') return NULL;
    }
    if (!count || count > size) return NULL;

    const uint8_t *match = NULL;
    size_t first = (4 - ((uintptr_t)start & 3)) & 3;
    for (size_t offset = first; offset <= size - count; offset += 4) {
        size_t i = 0;
        while (i < count && (wildcard[i] || start[offset + i] == bytes[i])) ++i;
        if (i == count) {
            if (match) return NULL; // An ambiguous signature must never be invoked.
            match = start + offset;
        }
    }
    return match;
}

static inline bool sa_decode_adrp_add(const uint8_t *instructions, uint64_t pc, uint64_t *target)
{
    uint32_t adrp, add;
    memcpy(&adrp, instructions, sizeof(adrp));
    memcpy(&add, instructions + 4, sizeof(add));
    if ((adrp & 0x9f000000) != 0x90000000 || (add & 0xffc00000) != 0x91000000) return false;
    uint32_t reg = adrp & 31;
    if ((add & 31) != reg || ((add >> 5) & 31) != reg) return false;
    int64_t pages = (((adrp >> 5) & 0x7ffff) << 2) | ((adrp >> 29) & 3);
    if (pages & (1 << 20)) pages -= 1 << 21;
    *target = (pc & ~0xfffULL) + pages * 4096 + ((add >> 10) & 0xfff);
    return true;
}

#endif
