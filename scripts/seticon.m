#import <Cocoa/Cocoa.h>

int main(int argc, char **argv)
{
    if (argc != 3) return 2;
    @autoreleasepool {
        NSString *imagePath = [NSString stringWithUTF8String:argv[1]];
        NSString *binaryPath = [NSString stringWithUTF8String:argv[2]];
        NSImage *image = [[NSImage alloc] initWithContentsOfFile:imagePath];
        if (!image) return 3;
        BOOL ok = [[NSWorkspace sharedWorkspace] setIcon:image forFile:binaryPath options:0];
        [image release];
        return ok ? 0 : 4;
    }
}
