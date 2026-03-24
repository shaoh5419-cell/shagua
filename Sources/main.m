#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "HUDApplication.h"
#import "HUDAppDelegate.h"
#import "GraphicsServices.h"
#import "BackboardServices.h"
#import "UIApplication+Private.h"

int main(int argc, char *argv[]) {
    @autoreleasepool {
        if (argc > 1 && strcmp(argv[1], "-hud") == 0) {
            [UIScreen initialize];
            CFRunLoopGetCurrent();

            GSInitialize();
            BKSDisplayServicesStart();
            UIApplicationInitialize();

            UIApplicationInstantiateSingleton([HUDApplication class]);
            HUDAppDelegate *delegate = [[HUDAppDelegate alloc] init];
            [[UIApplication sharedApplication] setDelegate:delegate];
            [[UIApplication sharedApplication] _accessibilityInit];

            [NSRunLoop currentRunLoop];

            GSEventInitialize(0);
            GSEventPushRunLoopMode(kCFRunLoopDefaultMode);

            [[UIApplication sharedApplication] __completeAndRunAsPlugin];
            CFRunLoopRun();
            return EXIT_SUCCESS;
        }

        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
