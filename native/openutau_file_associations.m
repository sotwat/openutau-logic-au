#import <AppKit/AppKit.h>
#import <CoreServices/CoreServices.h>

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        if (argc == 3 && strcmp(argv[1], "--query") == 0) {
            NSURL *file = [NSURL fileURLWithPath:@(argv[2])];
            NSURL *handler = [[NSWorkspace sharedWorkspace] URLForApplicationToOpenURL:file];
            printf("%s\n", handler.path.UTF8String ?: "(none)");
            return 0;
        }
        if (argc != 2) { return 2; }
        NSURL *app = [NSURL fileURLWithPath:@(argv[1]) isDirectory:YES];
        NSBundle *bundle = [NSBundle bundleWithURL:app];
        NSString *identifier = bundle.bundleIdentifier;
        if (![identifier isEqualToString:@"com.stakira.openutau"] ||
            ![bundle.infoDictionary[@"CFBundleDisplayName"] isEqualToString:@"OpenUtau AU"]) { return 3; }
        if (LSRegisterURL((__bridge CFURLRef)app, true) != noErr) { return 4; }
        for (NSString *extension in @[@"ust", @"ustx"]) {
            NSMutableSet *types = [NSMutableSet setWithObject:[@"moe.kakaru.openutau.logic-au" stringByAppendingFormat:@".%@", extension]];
            NSArray *registered = CFBridgingRelease(UTTypeCreateAllIdentifiersForTag(
                kUTTagClassFilenameExtension, (__bridge CFStringRef)extension, NULL));
            if (registered) { [types addObjectsFromArray:registered]; }
            for (NSString *type in types) {
                if (LSSetDefaultRoleHandlerForContentType((__bridge CFStringRef)type,
                        kLSRolesAll, (__bridge CFStringRef)identifier) != noErr) { return 5; }
                NSString *actual = CFBridgingRelease(LSCopyDefaultRoleHandlerForContentType(
                    (__bridge CFStringRef)type, kLSRolesAll));
                if (![actual isEqualToString:identifier]) { return 6; }
            }
            printf("%s: %s\n", extension.UTF8String, identifier.UTF8String);
        }
    }
    return 0;
}
