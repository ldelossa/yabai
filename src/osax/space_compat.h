#ifndef SA_SPACE_COMPAT_H
#define SA_SPACE_COMPAT_H

#include <Foundation/Foundation.h>
#include <CoreGraphics/CoreGraphics.h>
#include <objc/message.h>
#include <objc/runtime.h>
#include <stdint.h>
#include <stdbool.h>
#include <string.h>

static inline Ivar sa_object_ivar(id instance, const char *name)
{
    if (!instance) return NULL;
    Class cls = object_getClass(instance);
    Ivar ivar = class_getInstanceVariable(cls, name);
    if (!ivar) return NULL;
    ptrdiff_t offset = ivar_getOffset(ivar);
    if (offset < 0 || (size_t)offset + sizeof(id) > class_getInstanceSize(cls)) return NULL;
    return ivar;
}

static inline id sa_get_object_ivar(id instance, const char *name)
{
    Ivar ivar = sa_object_ivar(instance, name);
    if (!ivar) return nil;
    id result = nil;
    // Swift reference arrays are stored in the ivar as native NSArray-compatible storage.
    memcpy(&result, (const uint8_t *)instance + ivar_getOffset(ivar), sizeof(result));
    return result;
}

static inline NSArray *sa_display_spaces(id spaces)
{
    Ivar ivar = sa_object_ivar(spaces, "_displaySpaces");
    if (!ivar) return nil;
    // Inspect the raw Swift storage word before interpreting it as an object.
    // Tagged/bridged representations need a different bridge and fail closed here.
    uintptr_t storage = 0;
    memcpy(&storage, (const uint8_t *)spaces + ivar_getOffset(ivar), sizeof(storage));
    if (!storage || (storage & 0xc000000000000007ULL)) return nil;
    id array = (id)storage;
    if (![array respondsToSelector:@selector(countByEnumeratingWithState:objects:count:)] ||
        ![array respondsToSelector:@selector(objectAtIndex:)]) return nil;
    return array;
}

static inline id sa_current_space_for_display(id spaces, bool modern, CFStringRef uuid, id destination)
{
    if (!spaces || !uuid) return nil;
    SEL legacy = modern ? @selector(currentSpaceForDisplayUUID:) : @selector(currentSpaceforDisplayUUID:);
    if ([spaces respondsToSelector:legacy]) {
        return ((id (*)(id, SEL, CFStringRef))objc_msgSend)(spaces, legacy, uuid);
    }
    if (destination && [spaces respondsToSelector:@selector(displayIDForSpace:)] &&
        [spaces respondsToSelector:@selector(currentSpaceForDisplay:)]) {
        uint32_t display = ((uint32_t (*)(id, SEL, id))objc_msgSend)(spaces, @selector(displayIDForSpace:), destination);
        if (display) return ((id (*)(id, SEL, uint32_t))objc_msgSend)(spaces, @selector(currentSpaceForDisplay:), display);
    }
    return nil;
}

// Keep ownership explicit under MRC, on either a worker queue or Dock's main queue.
// Literal arrays are autoreleased: manually releasing those would double-release at pool drain.
static inline void sa_with_space_lists(uint64_t source_id, uint64_t destination_id, void (^work)(CFArrayRef, CFArrayRef))
{
    NSArray *source = [[NSArray alloc] initWithObjects:@(source_id), nil];
    NSArray *destination = [[NSArray alloc] initWithObjects:@(destination_id), nil];
    @try {
        work((__bridge CFArrayRef)source, (__bridge CFArrayRef)destination);
    } @finally {
        [destination release];
        [source release];
    }
}

static inline void sa_on_main_queue(void (^work)(void))
{
    if ([NSThread isMainThread]) work();
    else dispatch_sync(dispatch_get_main_queue(), work);
}

#endif
