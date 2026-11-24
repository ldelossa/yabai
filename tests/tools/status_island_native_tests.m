#import <Cocoa/Cocoa.h>
#import <ApplicationServices/ApplicationServices.h>
#import <objc/runtime.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

unsigned char __src_osax_payload[1];
unsigned int __src_osax_payload_len;
unsigned char __src_osax_loader[1];
unsigned int __src_osax_loader_len;

#include "../../src/manifest.m"

static int g_cases = 0;
static int g_failed = 0;

#define CHECK(cond, msg)                                            \
    do {                                                            \
        g_cases++;                                                  \
        if (!(cond)) {                                              \
            g_failed++;                                             \
            printf("FAIL %s:%d: %s\n", __FILE__, __LINE__, msg);    \
        }                                                           \
    } while (0)

// Receiver content view counts real WindowServer-delivered mouse downs.
@interface IslandReceiverView : NSView {
    int _clicks;
}
@property(nonatomic, readonly) int clicks;
@end

@implementation IslandReceiverView
@synthesize clicks = _clicks;
- (BOOL)acceptsFirstMouse:(NSEvent *)event { return YES; }
- (void)mouseDown:(NSEvent *)event
{
    _clicks++;
    printf("RECEIVER_CLICK %d\n", _clicks);
    fflush(stdout);
}
@end

static void drain_runloop(NSTimeInterval seconds)
{
    NSDate *until = [NSDate dateWithTimeIntervalSinceNow:seconds];
    [[NSRunLoop currentRunLoop] runUntilDate:until];
}

// Cocoa screen coordinates use bottom-left origin; CG event coordinates use
// top-left origin on the primary display.
static CGPoint toCGPoint(CGPoint cocoa, CGFloat screenHeight)
{
    return CGPointMake(cocoa.x, screenHeight - cocoa.y);
}

static void postClick(CGPoint point)
{
    CGEventRef down = CGEventCreateMouseEvent(NULL, kCGEventLeftMouseDown, point, kCGMouseButtonLeft);
    CGEventRef up = CGEventCreateMouseEvent(NULL, kCGEventLeftMouseUp, point, kCGMouseButtonLeft);
    CGEventPost(kCGHIDEventTap, down);
    usleep(60000);
    CGEventPost(kCGHIDEventTap, up);
    CFRelease(down);
    CFRelease(up);
    drain_runloop(0.15);
}

int main(void)
{
    @autoreleasepool {
        if (!AXIsProcessTrusted()) {
            printf("BLOCKED native-click-through: accessibility permission unavailable\n");
            return 77;
        }

        [NSApplication sharedApplication];
        [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];

        NSScreen *screen = [NSScreen screens].firstObject;
        if (!screen) {
            printf("BLOCKED native-click-through: no screen available\n");
            return 77;
        }
        CGFloat screenHeight = screen.frame.size.height;

        // Receiver at normal level; the status-level fixtures always sit above it.
        IslandReceiverView *receiverView = [[IslandReceiverView alloc] initWithFrame:NSMakeRect(0, 0, 120, 120)];
        NSWindow *receiver = [[NSWindow alloc] initWithContentRect:NSMakeRect(120, 120, 120, 120)
                                                         styleMask:NSWindowStyleMaskBorderless
                                                           backing:NSBackingStoreBuffered
                                                             defer:NO];
        receiver.contentView = receiverView;
        // Above floating panels (e.g. Macuake at level 3) and ordinary windows,
        // but below the status-level fixture (25) the probe must click through.
        receiver.level = NSStatusWindowLevel - 5;
        receiver.releasedWhenClosed = NO;
        [NSApp activateIgnoringOtherApps:YES];
        [receiver makeKeyAndOrderFront:nil];
        [receiverView release];
        drain_runloop(0.3);

        // A bare clang binary (no app bundle) cannot become the active app in
        // some launch contexts, so WindowServer routes synthesized HID clicks to
        // the real frontmost app rather than this process. Fail closed as blocked
        // instead of producing a misleading pass.
        if (!NSApp.isActive || !receiver.isKeyWindow) {
            printf("BLOCKED native-click-through: process cannot activate to receive synthesized clicks\n");
            return 77;
        }

        // Baseline: with no fixture above it, the receiver must see the click.
        printf("receiver frame=%s visible=%d level=%d\n", NSStringFromRect(receiver.frame).UTF8String, receiver.isVisible, (int)receiver.level);
        fflush(stdout);
        int baseline = receiverView.clicks;
        postClick(toCGPoint(CGPointMake(180, 180), screenHeight));
        CHECK(receiverView.clicks == baseline + 1, "baseline receiver click reaches receiver");
        printf("receiver baseline clicks=%d\n", receiverView.clicks);
        fflush(stdout);

        // Build the production island pair and reposition it away from the notch
        // so its bottom-left shadow margin covers the receiver center (180, 180).
        uint32_t did = 0;
        NSNumber *screenNumber = [screen deviceDescription][@"NSScreenNumber"];
        if (screenNumber) did = screenNumber.unsignedIntValue;

        status_island *island = [[status_island alloc] initWithDisplayID:did];
        [island show];

        NSPanel *input = nil;
        NSPanel *shadow = nil;
        object_getInstanceVariable(island, "_panel", (void **)&input);
        object_getInstanceVariable(island, "_shadow_panel", (void **)&shadow);
        CHECK(input != nil && shadow != nil, "island input/shadow pair available");
        if (input) printf("input.ignoresMouseEvents=%d frame=%s\n", input.ignoresMouseEvents, NSStringFromRect(input.frame).UTF8String);
        if (shadow) printf("shadow.ignoresMouseEvents=%d frame=%s\n", shadow.ignoresMouseEvents, NSStringFromRect(shadow.frame).UTF8String);
        fflush(stdout);

        if (!input || !shadow) {
            printf("FAIL native-click-through: no island pair\n");
            return 1;
        }

        // Input at (206,206); shadow therefore begins at (178,178). Receiver
        // center (180,180) is inside the shadow's bottom-left margin, outside input.
        NSRect inputFrame = input.frame;
        inputFrame.origin = NSMakePoint(206, 206);
        [input setFrame:inputFrame display:NO];
        NSRect shadowFrame = shadow.frame;
        shadowFrame.origin = NSMakePoint(inputFrame.origin.x - 28, inputFrame.origin.y - 28);
        [shadow setFrame:shadowFrame display:NO];
        [shadow orderFrontRegardless];
        [input orderFrontRegardless];
        drain_runloop(0.3);

        // 1) Shadow margin click passes through to the receiver.
        int before = receiverView.clicks;
        postClick(toCGPoint(CGPointMake(180, 180), screenHeight));
        CHECK(receiverView.clicks == before + 1, "shadow margin click reaches receiver");

        // 2) Visible input-panel click is owned by the island, not the receiver.
        before = receiverView.clicks;
        CGPoint inputCenter = CGPointMake(NSMidX(inputFrame), NSMidY(inputFrame));
        postClick(toCGPoint(inputCenter, screenHeight));
        CHECK(receiverView.clicks == before, "visible input click is intercepted by island");

        // 3) Negative control: a mouse-enabled window at the same expanded frame
        // must intercept, proving the receiver/probe are not simply immune.
        NSWindow *negative = [[NSWindow alloc] initWithContentRect:shadowFrame
                                                        styleMask:NSWindowStyleMaskBorderless
                                                          backing:NSBackingStoreBuffered
                                                            defer:NO];
        negative.level = NSStatusWindowLevel;
        negative.ignoresMouseEvents = NO;
        negative.backgroundColor = NSColor.clearColor;
        negative.releasedWhenClosed = NO;
        [negative orderFrontRegardless];
        drain_runloop(0.2);

        before = receiverView.clicks;
        postClick(toCGPoint(CGPointMake(180, 180), screenHeight));
        CHECK(receiverView.clicks == before, "mouse-enabled shadow intercepts click (negative control)");

        // Cleanup.
        [negative close];
        [negative release];
        [island hide];
        [island release];
        [receiver close];
        [receiver release];
    }

    printf("PASS native-click-through: %d cases\n", g_cases);
    return g_failed == 0 ? EXIT_SUCCESS : EXIT_FAILURE;
}
