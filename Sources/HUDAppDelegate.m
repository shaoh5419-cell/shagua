#import "HUDAppDelegate.h"
#import "FloatingWindow.h"
#import <notify.h>

@implementation HUDAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[FloatingWindow alloc] init];
    [self.window makeKeyAndVisible];
    [(FloatingWindow *)self.window show];

    // 监听停止通知，收到后退出
    int token;
    notify_register_dispatch("com.ddz.helper.hud.exit", &token, dispatch_get_main_queue(), ^(int t) {
        exit(0);
    });

    return YES;
}

@end
