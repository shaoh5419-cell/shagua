#import <UIKit/UIKit.h>
#import <dlfcn.h>
#import "AppDelegate.h"
#import "HUDApplication.h"
#import "HUDAppDelegate.h"

int main(int argc, char *argv[]) {
    @autoreleasepool {
        if (argc > 1 && strcmp(argv[1], "-hud") == 0) {
            void *handle = dlopen("/System/Library/PrivateFrameworks/GraphicsServices.framework/GraphicsServices", RTLD_LAZY);
            if (handle) {
                void (*GSInitialize)(void) = dlsym(handle, "GSInitialize");
                void (*GSEventInitialize)(int) = dlsym(handle, "GSEventInitialize");
                void (*GSEventPushRunLoopMode)(CFStringRef) = dlsym(handle, "GSEventPushRunLoopMode");

                if (GSInitialize) GSInitialize();

                [UIScreen initialize];
                CFRunLoopGetCurrent();

                void *bksHandle = dlopen("/System/Library/PrivateFrameworks/BackboardServices.framework/BackboardServices", RTLD_LAZY);
                if (bksHandle) {
                    void (*BKSDisplayServicesStart)(void) = dlsym(bksHandle, "BKSDisplayServicesStart");
                    if (BKSDisplayServicesStart) BKSDisplayServicesStart();
                }

                void (*UIApplicationInitialize)(void) = dlsym(RTLD_DEFAULT, "UIApplicationInitialize");
                void (*UIApplicationInstantiateSingleton)(Class) = dlsym(RTLD_DEFAULT, "UIApplicationInstantiateSingleton");

                if (UIApplicationInitialize) UIApplicationInitialize();
                if (UIApplicationInstantiateSingleton) UIApplicationInstantiateSingleton([HUDApplication class]);

                HUDAppDelegate *delegate = [[HUDAppDelegate alloc] init];
                [[UIApplication sharedApplication] setDelegate:delegate];
                [[UIApplication sharedApplication] performSelector:@selector(_accessibilityInit)];

                [NSRunLoop currentRunLoop];

                if (@available(iOS 15.0, *)) {
                    if (GSEventInitialize) GSEventInitialize(0);
                    if (GSEventPushRunLoopMode) GSEventPushRunLoopMode(kCFRunLoopDefaultMode);
                }

                [[UIApplication sharedApplication] performSelector:@selector(__completeAndRunAsPlugin)];
                CFRunLoopRun();
            }
            return EXIT_SUCCESS;
        }

        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
