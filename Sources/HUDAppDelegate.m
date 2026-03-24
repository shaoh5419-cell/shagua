#import "HUDAppDelegate.h"
#import "FloatingWindow.h"
#import "SBSAccessibilityWindowHostingController.h"
#import "UIWindow+Private.h"

@implementation HUDAppDelegate {
    SBSAccessibilityWindowHostingController *_windowHostingController;
    FloatingWindow *_floatingWindow;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    NSLog(@"[HUD] HUDAppDelegate 启动");

    _floatingWindow = [[FloatingWindow alloc] init];
    self.window = _floatingWindow;

    [self.window setWindowLevel:10000010.0];
    [self.window setHidden:NO];
    [self.window makeKeyAndVisible];

    [_floatingWindow addLog:@"HUD 进程已启动"];
    [_floatingWindow show];
    [_floatingWindow addLog:@"悬浮窗已显示"];

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

    [_floatingWindow addLog:@"HUDAppDelegate 启动完成"];

    return YES;
}

@end
