#import "FloatingWindow.h"
#import "GameStateManager.h"

@interface FloatingWindow ()
@property (nonatomic, strong) UILabel *displayLabel;
@property (nonatomic, strong) GameStateManager *gameManager;
@property (nonatomic, strong) UIViewController *rootVC;
@end

@implementation FloatingWindow

+ (BOOL)_isSystemWindow { return YES; }
- (BOOL)_isWindowServerHostingManaged { return NO; }
- (BOOL)_isSecure { return YES; }
- (BOOL)_shouldCreateContextAsSecure { return YES; }

- (instancetype)init {
    CGFloat width = 200;
    CGFloat height = 80;
    CGRect frame = CGRectMake(20, 100, width, height);

    self = [super initWithFrame:frame];

    if (self) {
        self.frame = frame;
        self.windowLevel = UIWindowLevelStatusBar + 100;
        self.backgroundColor = [UIColor clearColor];

        self.rootVC = [[UIViewController alloc] init];
        self.rootViewController = self.rootVC;

        // 创建背景视图
        UIView *bgView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
        bgView.backgroundColor = [UIColor colorWithWhite:0.05 alpha:0.9];
        bgView.layer.cornerRadius = 12;
        bgView.layer.borderWidth = 2;
        bgView.layer.borderColor = [UIColor colorWithRed:0.2 green:0.5 blue:1.0 alpha:0.6].CGColor;
        [self.rootVC.view addSubview:bgView];

        // 创建标题标签
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 5, width-20, 20)];
        titleLabel.text = @"AI助手";
        titleLabel.textColor = [UIColor colorWithRed:0.4 green:0.7 blue:1.0 alpha:1.0];
        titleLabel.font = [UIFont boldSystemFontOfSize:12];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        [self.rootVC.view addSubview:titleLabel];

        // 创建显示标签
        self.displayLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 25, width-20, height-30)];
        self.displayLabel.textColor = [UIColor whiteColor];
        self.displayLabel.font = [UIFont systemFontOfSize:14];
        self.displayLabel.numberOfLines = 0;
        self.displayLabel.textAlignment = NSTextAlignmentCenter;
        self.displayLabel.text = @"等待识别...";
        [self.rootVC.view addSubview:self.displayLabel];

        // 添加手势
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [self.rootVC.view addGestureRecognizer:pan];

        // 初始化游戏管理器
        self.gameManager = [[GameStateManager alloc] init];
        __weak typeof(self) weakSelf = self;
        self.gameManager.onResultUpdate = ^(NSString *result) {
            [weakSelf updateText:result];
        };
    }
    return self;
}

- (void)show {
    self.hidden = NO;
    [self makeKeyAndVisible];
    [self.gameManager startMonitoring];
}

- (void)hide {
    [self.gameManager stopMonitoring];
    self.hidden = YES;
}

- (void)updateText:(NSString *)text {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.displayLabel.text = text;
    });
}

- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    CGPoint translation = [gesture translationInView:self];
    CGPoint newCenter = CGPointMake(self.center.x + translation.x, self.center.y + translation.y);

    CGRect screenBounds = [UIScreen mainScreen].bounds;
    newCenter.x = MAX(self.frame.size.width/2, MIN(newCenter.x, screenBounds.size.width - self.frame.size.width/2));
    newCenter.y = MAX(self.frame.size.height/2, MIN(newCenter.y, screenBounds.size.height - self.frame.size.height/2));

    self.center = newCenter;
    [gesture setTranslation:CGPointZero inView:self];
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    return YES;
}

@end
