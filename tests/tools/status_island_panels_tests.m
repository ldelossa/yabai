#import <Cocoa/Cocoa.h>
#include <stdio.h>
#include <stdlib.h>

unsigned char __src_osax_payload[1];
unsigned int __src_osax_payload_len;
unsigned char __src_osax_loader[1];
unsigned int __src_osax_loader_len;

#include "../../src/manifest.m"

#include <objc/runtime.h>

// Named category is allowed after the implementation and exposes the private
// menu-panel factories without modifying production code.
@interface status_island (IslandInputTests)
- (NSPanel *)makeMenuInputPanelWithWidth:(CGFloat)width height:(CGFloat)height;
- (NSPanel *)makeMenuShadowPanelWithWidth:(CGFloat)width height:(CGFloat)height;
@end

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

static bool nearly(double a, double b)
{
    double d = a - b;
    return d < 0.5 && d > -0.5;
}

int main(void)
{
    @autoreleasepool {
        [NSApplication sharedApplication];
        [NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];

        // Menu factories: tight input + mouse-transparent shadow decoration.
        {
            status_island *island = [[status_island alloc] initWithDisplayID:0];
            NSPanel *input = [island makeMenuInputPanelWithWidth:230.0 height:102.0];
            NSPanel *shadow = [island makeMenuShadowPanelWithWidth:230.0 height:102.0];

            CHECK(input != nil && shadow != nil, "menu pair created");
            CHECK(input.ignoresMouseEvents == NO, "menu input panel accepts mouse");
            CHECK(shadow.ignoresMouseEvents == YES, "menu shadow panel ignores mouse");
            CHECK(input.level == NSStatusWindowLevel, "menu input level unchanged");
            CHECK(shadow.level == NSStatusWindowLevel, "menu shadow level unchanged");
            CHECK(nearly(input.frame.size.width, 230.0) && nearly(input.frame.size.height, 102.0),
                  "menu input frame is tight");
            CHECK(nearly(shadow.frame.size.width, 230.0 + 2.0 * 28.0) && nearly(shadow.frame.size.height, 102.0 + 28.0),
                  "menu shadow frame includes margins");

            [input close];
            [shadow close];
            [input release];
            [shadow release];
            [island release];
        }

        // Island pair: tight interactive panel + mouse-transparent shadow panel.
        {
            uint32_t did = 0;
            NSScreen *screen = [NSScreen screens].firstObject;
            if (screen) {
                NSNumber *number = [screen deviceDescription][@"NSScreenNumber"];
                if (number) did = number.unsignedIntValue;
            }

            status_island *island = [[status_island alloc] initWithDisplayID:did];
            [island show];

            NSPanel *input = nil;
            NSPanel *shadow = nil;
            object_getInstanceVariable(island, "_panel", (void **)&input);
            object_getInstanceVariable(island, "_shadow_panel", (void **)&shadow);

            CHECK(input != nil && shadow != nil, "island pair created");
            if (input && shadow) {
                CHECK(input.ignoresMouseEvents == NO, "island input panel accepts mouse");
                CHECK(shadow.ignoresMouseEvents == YES, "island shadow panel ignores mouse");
                CHECK(input.level == NSStatusWindowLevel, "island input level unchanged");
                CHECK(shadow.level == NSStatusWindowLevel, "island shadow level unchanged");
                CHECK(nearly(shadow.frame.size.width, input.frame.size.width + 2.0 * 28.0),
                      "island shadow width equals input width plus margins");
                CHECK(nearly(shadow.frame.size.height, input.frame.size.height + 28.0),
                      "island shadow height equals input height plus bottom margin");
                CHECK(nearly(shadow.frame.origin.x, input.frame.origin.x - 28.0),
                      "island shadow x aligns left of input");
                CHECK(nearly(shadow.frame.origin.y, input.frame.origin.y - 28.0),
                      "island shadow y aligns below input");
            }

            [island hide];
            if (input && shadow) {
                CHECK(!input.isVisible, "island input ordered out");
                CHECK(!shadow.isVisible, "island shadow ordered out");
            }
            [island release];
        }
    }

    printf("PASS panels: %d cases\n", g_cases);
    return g_failed == 0 ? EXIT_SUCCESS : EXIT_FAILURE;
}
