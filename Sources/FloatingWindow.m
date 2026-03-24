#import "FloatingWindow.h"
#import "GameStateManager.h"

@interface FloatingWindow ()
@property (nonatomic, strong) UILabel *displayLabel;
@property (nonatomic, strong) UIView *indicatorDot;
@property (nonatomic, strong) GameStateManager *gameManager;
@property (nonatomic, strong) UIViewController *rootVC;
@end

@implementation FloatingWindow

+ (BOOL)_isSystemWindow { return YES; }
- (BOOL)_isWindowServerHostingManaged { return NO; }
- (BOOL)_isSecure { return YES; }
- (BOOL)_shouldCreateContextAsSecure { return YES; }

- (instancetype)init {
    CGRect screen = [UIScreen mainScreen].bounds;

    // 竖向窄条：宽68，高200
    CGFloat w = 68;
    CGFloat h = 200;

    // 贴紧 portrait 右边缘，垂直居中偏上
    CGFloat x = screen.size.width - w;
    CGFloat y = screen.size.height * 0.35 - h / 2;

    self = [super initWithFrame:CGRectMake(x, y, w, h)];
    if (!self) return nil;

    self.windowLevel = 10000010.0;
    self.backgroundColor = [UIColor clearColor];
    self.opaque = NO;

    self.rootVC = [[UIViewController alloc] init];
    self.rootVC.view.backgroundColor = [UIColor clearColor];
    self.rootViewController = self.rootVC;

    // 背景容器：竖长条，左侧圆角
    UIView *bg = [[UIView alloc] initWithFrame:CGRectMake(0, 0, w, h)];
    bg.backgroundColor = [UIColor colorWithRed:0.06 green:0.06 blue:0.12 alpha:0.94];
    bg.layer.cornerRadius = w / 2;
    bg.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMinXMaxYCorner;  // 左侧圆角
    bg.layer.borderWidth = 1.0;
    bg.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.12].CGColor;
    bg.layer.shadowColor = [UIColor blackColor].CGColor;
    bg.layer.shadowOffset = CGSizeMake(-3, 3);
    bg.layer.shadowRadius = 8;
    bg.layer.shadowOpacity = 0.55;
    [self.rootVC.view addSubview:bg];

    // 顶部蓝色横条
    UIView *topStripe = [[UIView alloc] initWithFrame:CGRectMake(0, 0, w, 4)];
    topStripe.backgroundColor = [UIColor colorWithRed:0.18 green:0.72 blue:1.0 alpha:1.0];
    UIView *stripeWrap = [[UIView alloc] initWithFrame:CGRectMake(0, 0, w, 16)];
    stripeWrap.clipsToBounds = YES;
    stripeWrap.layer.cornerRadius = w / 2;
    stripeWrap.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    [stripeWrap addSubview:topStripe];
    [bg addSubview:stripeWrap];

    // "AI" 标签（顶部）
    UILabel *aiLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 16, w, 30)];
    aiLabel.text = @"AI";
    aiLabel.textColor = [UIColor colorWithRed:0.18 green:0.72 blue:1.0 alpha:1.0];
    aiLabel.font = [UIFont boldSystemFontOfSize:14];
    aiLabel.textAlignment = NSTextAlignmentCenter;
    [bg addSubview:aiLabel];

    // 横向分隔线
    UIView *sep = [[UIView alloc] initWithFrame:CGRectMake(12, 48, w - 24, 1)];
    sep.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.12];
    [bg addSubview:sep];

    // 指示点（居中）
    UIView *dot = [[UIView alloc] initWithFrame:CGRectMake((w - 8) / 2, 60, 8, 8)];
    dot.layer.cornerRadius = 4;
    dot.backgroundColor = [UIColor colorWithRed:0.18 green:0.72 blue:1.0 alpha:0.6];
    self.indicatorDot = dot;
    [bg addSubview:dot];

    // 主文本标签（竖向排列，旋转90度）
    self.displayLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 75, w, h - 80)];
    self.displayLabel.textColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    self.displayLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    self.displayLabel.numberOfLines = 0;
    self.displayLabel.textAlignment = NSTextAlignmentCenter;
    self.displayLabel.text = @"等待\n识别...";
    [bg addSubview:self.displayLabel];

    // 拖动手势（仅 y 轴）
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [bg addGestureRecognizer:pan];

    // 游戏状态
    self.gameManager = [[GameStateManager alloc] init];
    __weak typeof(self) weakSelf = self;
    self.gameManager.onResultUpdate = ^(NSString *result) {
        dispatch_async(dispatch_get_main_queue(), ^{
            // 短文本换行显示
            NSString *formatted = [result stringByReplacingOccurrencesOfString:@" " withString:@"\n"];
            weakSelf.displayLabel.text = formatted;

            // 指示点闪烁
            [UIView animateWithDuration:0.15 animations:^{
                weakSelf.indicatorDot.alpha = 0.3;
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:0.15 animations:^{
                    weakSelf.indicatorDot.alpha = 1.0;
                }];
            }];
        });
    };

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

// 只允许上下拖动，x 始终贴在右边缘
- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    CGPoint delta = [gesture translationInView:self];
    CGRect screen = [UIScreen mainScreen].bounds;
    CGFloat newY = self.frame.origin.y + delta.y;
    newY = MAX(0, MIN(newY, screen.size.height - self.frame.size.height));
    self.frame = CGRectMake(screen.size.width - self.frame.size.width,
                            newY,
                            self.frame.size.width,
                            self.frame.size.height);
    [gesture setTranslation:CGPointZero inView:self];
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    return YES;
}

@end
