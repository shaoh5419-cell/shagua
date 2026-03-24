#import "HUDAppDelegate.h"
#import "FloatingWindow.h"

@implementation HUDAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[FloatingWindow alloc] init];
    [self.window makeKeyAndVisible];
    [(FloatingWindow *)self.window show];
    return YES;
}

@end
