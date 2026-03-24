#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "HUDApplication.h"
#import "HUDAppDelegate.h"
#import "GraphicsServices.h"
#import "BackboardServices.h"
#import "UIApplication+Private.h"
#import <mach-o/dyld.h>
#import <sys/wait.h>
#import <unistd.h>

#define PID_FILE "/var/mobile/Library/Caches/com.ddz.helper.pid"

int main(int argc, char *argv[]) {
    @autoreleasepool {
        if (argc > 1 && strcmp(argv[1], "-hud") == 0) {
            // 保存PID到文件，供-exit时kill使用
            pid_t pid = getpid();
            NSString *pidStr = [NSString stringWithFormat:@"%d", pid];
            [pidStr writeToFile:@(PID_FILE) atomically:YES encoding:NSUTF8StringEncoding error:nil];

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
        else if (argc > 1 && strcmp(argv[1], "-exit") == 0) {
            // 读取PID文件并kill HUD进程
            NSString *pidStr = [NSString stringWithContentsOfFile:@(PID_FILE)
                                                         encoding:NSUTF8StringEncoding
                                                            error:nil];
            if (pidStr) {
                pid_t hudPid = (pid_t)[pidStr intValue];
                kill(hudPid, SIGKILL);
                unlink(PID_FILE);
            }
            return EXIT_SUCCESS;
        }

        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
