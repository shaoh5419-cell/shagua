#import "RootViewController.h"
#import "FloatingWindow.h"

@interface RootViewController ()
@property (nonatomic, strong) UIButton *startButton;
@property (nonatomic, strong) FloatingWindow *floatingWindow;
@end

@implementation RootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.15 alpha:1.0];

    // 创建启动按钮
    self.startButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.startButton.frame = CGRectMake(0, 0, 200, 200);
    self.startButton.center = self.view.center;
    self.startButton.layer.cornerRadius = 100;
    self.startButton.backgroundColor = [UIColor colorWithRed:0.2 green:0.6 blue:1.0 alpha:1.0];
    [self.startButton setTitle:@"启动" forState:UIControlStateNormal];
    self.startButton.titleLabel.font = [UIFont boldSystemFontOfSize:32];
    [self.startButton addTarget:self action:@selector(startButtonTapped) forControlEvents:UIControlEventTouchUpInside];

    // 添加阴影
    self.startButton.layer.shadowColor = [UIColor blackColor].CGColor;
    self.startButton.layer.shadowOffset = CGSizeMake(0, 4);
    self.startButton.layer.shadowRadius = 10;
    self.startButton.layer.shadowOpacity = 0.3;

    [self.view addSubview:self.startButton];
}

- (void)startButtonTapped {
    if (!self.floatingWindow) {
        self.floatingWindow = [[FloatingWindow alloc] init];
    }
    [self.floatingWindow show];

    // 将应用退到后台
    [[UIApplication sharedApplication] performSelector:@selector(suspend)];
}

@end
