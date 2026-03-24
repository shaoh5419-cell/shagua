#import "HUDAppDelegate.h"
#import "FloatingWindow.h"
#import "SBSAccessibilityWindowHostingController.h"
#import "UIWindow+Private.h"
#import <notify.h>

@implementation HUDAppDelegate {
    SBSAccessibilityWindowHostingController *_windowHostingController;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    FloatingWindow *floatingWindow = [[FloatingWindow alloc] init];
    self.window = floatingWindow;

    [self.window setWindowLevel:10000010.0];
    [self.window setHidden:NO];
    [self.window makeKeyAndVisible];
    [floatingWindow show];

    // 关键：向SpringBoard注册窗口，使其全局可见
    _windowHostingController = [[SBSAccessibilityWindowHostingController alloc] init];
    unsigned int contextId = [self.window _contextId];
    double windowLevel = [self.window windowLevel];

    // 使用NSInvocation调用registerWindowWithContextID:atLevel:
    NSMethodSignature *signature = [NSMethodSignature signatureWithObjCTypes:"v@:Id"];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    [invocation setTarget:_windowHostingController];
    [invocation setSelector:NSSelectorFromString(@"registerWindowWithContextID:atLevel:")];
    [invocation setArgument:&contextId atIndex:2];
    [invocation setArgument:&windowLevel atIndex:3];
    [invocation invoke];

    // 监听停止通知，收到后退出
    int token;
    notify_register_dispatch("com.ddz.helper.hud.exit", &token, dispatch_get_main_queue(), ^(int t) {
        // 淡出动画后退出
        [UIView animateWithDuration:0.3 animations:^{
            [self.window setAlpha:0.0];
        } completion:^(BOOL finished) {
            exit(0);
        }];
    });

    return YES;
}

@end
