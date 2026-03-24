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
        if (!self.floatingWindow) {
            self.floatingWindow = [[FloatingWindow alloc] init];
        }
        [self.floatingWindow show];
        self.startButton.selected = YES;
        self.isRunning = YES;

        // 提示用户切换到其他应用
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示"
            message:@"悬浮窗已启动，请切换到其他应用查看"
            preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            // 延迟退到后台
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [[UIApplication sharedApplication] performSelector:@selector(suspend)];
            });
        }]];
        [self presentViewController:alert animated:YES completion:nil];
    } else {
        [self.floatingWindow hide];
        self.startButton.selected = NO;
        self.isRunning = NO;
    }
}

@end
