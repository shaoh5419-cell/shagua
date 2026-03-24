#import "AppDelegate.h"
#import "RootViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface AppDelegate ()
@property (nonatomic, strong) AVAudioPlayer *audioPlayer;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.backgroundColor = [UIColor blackColor];

    RootViewController *rootVC = [[RootViewController alloc] init];
    self.window.rootViewController = rootVC;
    [self.window makeKeyAndVisible];

    // 后台保活
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setupBackgroundAudio];
    });

    return YES;
}

- (void)setupBackgroundAudio {
    NSError *error = nil;
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionMixWithOthers error:&error];
    if (error) {
        NSLog(@"Audio session error: %@", error);
        return;
    }
    [session setActive:YES error:&error];
}

@end
