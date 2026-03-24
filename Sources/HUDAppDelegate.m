#import "HUDAppDelegate.h"
#import "FloatingWindow.h"
#import "SBSAccessibilityWindowHostingController.h"
#import "UIWindow+Private.h"

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

    return YES;
}

@end
