#import "RootViewController.h"
#import "FloatingWindow.h"
#import <spawn.h>

extern char **environ;

@interface RootViewController ()
@property (nonatomic, strong) UIButton *startButton;
@property (nonatomic, strong) FloatingWindow *floatingWindow;
@property (nonatomic, assign) BOOL isRunning;
@end

@implementation RootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithRed:0.05 green:0.05 blue:0.1 alpha:1.0];

    // 创建启动按钮
    self.startButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.startButton.frame = CGRectMake(0, 0, 180, 180);
    self.startButton.center = self.view.center;
    self.startButton.layer.cornerRadius = 90;

    // 渐变背景
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = self.startButton.bounds;
    gradient.colors = @[(id)[UIColor colorWithRed:0.2 green:0.5 blue:1.0 alpha:1.0].CGColor,
                        (id)[UIColor colorWithRed:0.4 green:0.7 blue:1.0 alpha:1.0].CGColor];
    gradient.cornerRadius = 90;
    [self.startButton.layer insertSublayer:gradient atIndex:0];

    [self.startButton setTitle:@"启动" forState:UIControlStateNormal];
    [self.startButton setTitle:@"运行中" forState:UIControlStateSelected];
    self.startButton.titleLabel.font = [UIFont boldSystemFontOfSize:28];
    [self.startButton addTarget:self action:@selector(startButtonTapped) forControlEvents:UIControlEventTouchUpInside];

    // 阴影
    self.startButton.layer.shadowColor = [UIColor colorWithRed:0.2 green:0.5 blue:1.0 alpha:1.0].CGColor;
    self.startButton.layer.shadowOffset = CGSizeMake(0, 8);
    self.startButton.layer.shadowRadius = 20;
    self.startButton.layer.shadowOpacity = 0.5;

    [self.view addSubview:self.startButton];
}

- (void)startButtonTapped {
    if (!self.isRunning) {
        // 检查并安装plist文件
        NSString *plistPath = @"/Library/LaunchDaemons/com.ddz.helper.daemon.plist";
        if (![[NSFileManager defaultManager] fileExistsAtPath:plistPath]) {
            // 从应用bundle复制plist到系统目录
            NSString *bundlePlist = [[NSBundle mainBundle] pathForResource:@"com.ddz.helper.daemon" ofType:@"plist"];
            if (bundlePlist) {
                NSError *error = nil;
                [[NSFileManager defaultManager] copyItemAtPath:bundlePlist toPath:plistPath error:&error];
                if (error) {
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"错误"
                        message:[NSString stringWithFormat:@"无法安装配置文件: %@", error.localizedDescription]
                        preferredStyle:UIAlertControllerStyleAlert];
                    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
                    [self presentViewController:alert animated:YES completion:nil];
                    return;
                }
            } else {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"错误"
                    message:@"应用包中缺少配置文件"
                    preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
                [self presentViewController:alert animated:YES completion:nil];
                return;
            }
        }

        // 启动daemon
        posix_spawnattr_t attr;
        posix_spawnattr_init(&attr);

        pid_t pid;
        const char *path = "/usr/bin/launchctl";
        const char *args[] = {path, "load", [plistPath UTF8String], NULL};
        int result = posix_spawn(&pid, path, NULL, &attr, (char **)args, environ);
        posix_spawnattr_destroy(&attr);

        if (result == 0) {
            self.startButton.selected = YES;
            self.isRunning = YES;

            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"成功"
                message:@"悬浮窗已启动"
                preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
        } else {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"错误"
                message:[NSString stringWithFormat:@"启动失败: %d (%s)", result, strerror(result)]
                preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
        }
    } else {
        // 停止daemon
        posix_spawnattr_t attr;
        posix_spawnattr_init(&attr);

        pid_t pid;
        const char *path = "/usr/bin/launchctl";
        const char *args[] = {path, "unload", "/Library/LaunchDaemons/com.ddz.helper.daemon.plist", NULL};
        posix_spawn(&pid, path, NULL, &attr, (char **)args, environ);
        posix_spawnattr_destroy(&attr);

        self.startButton.selected = NO;
        self.isRunning = NO;
    }
}

@end
