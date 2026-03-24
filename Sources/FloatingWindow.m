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
    CGRect screen = [UIScreen mainScreen].bounds;
    CGFloat w = 200;
    CGFloat h = 64;

    // 贴紧 portrait 右边缘；只在 y 方向可拖动
    CGFloat x = screen.size.width - w;
    CGFloat y = screen.size.height * 0.38 - h / 2;

    self = [super initWithFrame:CGRectMake(x, y, w, h)];
    if (!self) return nil;

    self.windowLevel = 10000010.0;
    self.backgroundColor = [UIColor clearColor];
    self.opaque = NO;

    self.rootVC = [[UIViewController alloc] init];
    self.rootVC.view.backgroundColor = [UIColor clearColor];
    self.rootViewController = self.rootVC;

    // 背景：右侧贴边所以只圆左两角，制造"嵌入屏幕边缘"的视感
    UIView *bg = [[UIView alloc] initWithFrame:CGRectMake(0, 0, w, h)];
    bg.backgroundColor = [UIColor colorWithRed:0.06 green:0.06 blue:0.12 alpha:0.94];
    bg.layer.cornerRadius = h / 2;
    bg.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMinXMaxYCorner;
    bg.layer.borderWidth = 1.0;
    bg.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.12].CGColor;
    bg.layer.shadowColor = [UIColor blackColor].CGColor;
    bg.layer.shadowOffset = CGSizeMake(-3, 3);
    bg.layer.shadowRadius = 8;
    bg.layer.shadowOpacity = 0.55;
    [self.rootVC.view addSubview:bg];

    // 左侧彩条（圆角，配合背景）
    UIView *stripe = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 4, h)];
    stripe.backgroundColor = [UIColor colorWithRed:0.18 green:0.72 blue:1.0 alpha:1.0];
    UIView *stripeWrap = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 14, h)];
    stripeWrap.clipsToBounds = YES;
    stripeWrap.layer.cornerRadius = h / 2;
    stripeWrap.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMinXMaxYCorner;
    [stripeWrap addSubview:stripe];
    [bg addSubview:stripeWrap];

    // "AI" 标签
    UILabel *aiLabel = [[UILabel alloc] initWithFrame:CGRectMake(8, 0, 28, h)];
    aiLabel.text = @"AI";
    aiLabel.textColor = [UIColor colorWithRed:0.18 green:0.72 blue:1.0 alpha:1.0];
    aiLabel.font = [UIFont boldSystemFontOfSize:11];
    aiLabel.textAlignment = NSTextAlignmentCenter;
    [bg addSubview:aiLabel];

    // 竖分隔线
    UIView *sep = [[UIView alloc] initWithFrame:CGRectMake(36, 12, 1, h - 24)];
    sep.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.12];
    [bg addSubview:sep];

    // 主文本
    self.displayLabel = [[UILabel alloc] initWithFrame:CGRectMake(44, 0, w - 50, h)];
    self.displayLabel.textColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    self.displayLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    self.displayLabel.numberOfLines = 2;
    self.displayLabel.textAlignment = NSTextAlignmentLeft;
    self.displayLabel.text = @"等待识别...";
    [bg addSubview:self.displayLabel];

    // 拖动手势（仅 y 轴）
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [bg addGestureRecognizer:pan];

    // 游戏状态
    self.gameManager = [[GameStateManager alloc] init];
    __weak typeof(self) weakSelf = self;
    self.gameManager.onResultUpdate = ^(NSString *result) {
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.displayLabel.text = result;
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
    // x 锁定在右边缘
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
