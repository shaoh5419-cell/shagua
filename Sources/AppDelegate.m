#import "AppDelegate.h"
#import "RootViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface AppDelegate ()
@property (nonatomic, strong) AVAudioPlayer *audioPlayer;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.rootViewController = [[RootViewController alloc] init];
    [self.window makeKeyAndVisible];

    // 后台保活
    [self setupBackgroundAudio];

    return YES;
}

- (void)setupBackgroundAudio {
    NSError *error = nil;
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionMixWithOthers error:&error];
    [session setActive:YES error:&error];

    // 播放静音音频保持后台运行
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"silence" withExtension:@"mp3"];
    if (!url) {
        // 创建1秒静音数据
        NSMutableData *data = [NSMutableData dataWithLength:44100];
        url = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"silence.mp3"]];
        [data writeToURL:url atomically:YES];
    }

    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
    self.audioPlayer.numberOfLoops = -1;
    self.audioPlayer.volume = 0.01;
    [self.audioPlayer play];
}

@end
