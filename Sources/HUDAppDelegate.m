#import "HUDAppDelegate.h"
#import "FloatingWindow.h"
#import "SBSAccessibilityWindowHostingController.h"
#import "UIWindow+Private.h"

@interface HUDAppDelegate ()
@property (nonatomic, strong) UITextView *debugView;
@end

@implementation HUDAppDelegate {
    SBSAccessibilityWindowHostingController *_windowHostingController;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    NSLog(@"[HUD] HUDAppDelegate 启动");

    // 创建调试窗口
    [self createDebugWindow];
    [self addDebugLog:@"HUD 进程已启动"];

    FloatingWindow *floatingWindow = [[FloatingWindow alloc] init];
    self.window = floatingWindow;

    [self.window setWindowLevel:10000010.0];
    [self.window setHidden:NO];
    [self.window makeKeyAndVisible];

    [self addDebugLog:@"悬浮窗已创建"];
    [floatingWindow show];
    [self addDebugLog:@"悬浮窗已显示，调用 startMonitoring"];

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

    [self addDebugLog:@"HUDAppDelegate 启动完成"];

    return YES;
}

- (void)createDebugWindow {
    CGRect screen = [UIScreen mainScreen].bounds;
    // 放在顶部，高度 200
    UIWindow *debugWindow = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, screen.size.width, 200)];
    debugWindow.windowLevel = 10000050.0;  // 比悬浮窗更高
    debugWindow.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:0.95];

    UIViewController *vc = [[UIViewController alloc] init];
    vc.view.backgroundColor = [UIColor clearColor];
    debugWindow.rootViewController = vc;

    self.debugView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, screen.size.width, 200)];
    self.debugView.backgroundColor = [UIColor colorWithRed:0.05 green:0.05 blue:0.05 alpha:1.0];
    self.debugView.textColor = [UIColor colorWithRed:1.0 green:1.0 blue:0.0 alpha:1.0];
    self.debugView.font = [UIFont systemFontOfSize:10];
    self.debugView.editable = NO;
    self.debugView.scrollEnabled = YES;
    [vc.view addSubview:self.debugView];

    [debugWindow makeKeyAndVisible];

    NSLog(@"[HUD] 调试窗口已创建");
}

- (void)addDebugLog:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.debugView) {
            NSLog(@"[HUD] debugView 为 nil");
            return;
        }

        NSString *timestamp = [self getCurrentTimestamp];
        NSString *logLine = [NSString stringWithFormat:@"[%@] %@\n", timestamp, message];
        self.debugView.text = [self.debugView.text stringByAppendingString:logLine];

        // 自动滚动到底部
        if (self.debugView.text.length > 0) {
            [self.debugView scrollRangeToVisible:NSMakeRange(self.debugView.text.length - 1, 1)];
        }

        NSLog(@"[HUD] %@", message);
    });
}

- (NSString *)getCurrentTimestamp {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"HH:mm:ss.SSS";
    return [formatter stringFromDate:[NSDate date]];
}

@end
