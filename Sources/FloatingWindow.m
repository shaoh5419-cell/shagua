#import "FloatingWindow.h"
#import "GameStateManager.h"

@interface FloatingWindow ()
@property (nonatomic, strong) UILabel *displayLabel;
@property (nonatomic, strong) UIView *statusIndicator;
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) GameStateManager *gameManager;
@property (nonatomic, strong) UIViewController *rootVC;
@property (nonatomic, strong) UIPanGestureRecognizer *panGesture;
@property (nonatomic, assign) CGFloat initialY;
@end

@implementation FloatingWindow

+ (BOOL)_isSystemWindow { return YES; }
- (BOOL)_isWindowServerHostingManaged { return NO; }
- (BOOL)_isSecure { return YES; }
- (BOOL)_shouldCreateContextAsSecure { return YES; }

- (instancetype)init {
    CGRect screen = [UIScreen mainScreen].bounds;

    // 竖向侧边栏：宽58，高200
    CGFloat w = 58;
    CGFloat h = 200;

    // 贴紧右边缘，垂直居中
    CGFloat x = screen.size.width - w;
    CGFloat y = (screen.size.height - h) / 2;

    self = [super initWithFrame:CGRectMake(x, y, w, h)];
    if (!self) return nil;

    self.windowLevel = 10000010.0;
    self.backgroundColor = [UIColor clearColor];
    self.opaque = NO;

    self.rootVC = [[UIViewController alloc] init];
    self.rootVC.view.backgroundColor = [UIColor clearColor];
    self.rootViewController = self.rootVC;

    // ═══ 主容器 ═══
    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, w, h)];
    container.backgroundColor = [UIColor colorWithRed:0.03 green:0.03 blue:0.08 alpha:0.97];
    container.layer.cornerRadius = w / 2;
    container.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMinXMaxYCorner;
    container.clipsToBounds = YES;  // 关键：裁剪子视图到圆角边界
    self.containerView = container;

    // 边框
    container.layer.borderWidth = 1.3;
    container.layer.borderColor = [UIColor colorWithRed:0.12 green:0.60 blue:0.95 alpha:0.4].CGColor;

    // 投影
    container.layer.shadowColor = [UIColor blackColor].CGColor;
    container.layer.shadowOffset = CGSizeMake(-2, 2);
    container.layer.shadowRadius = 8;
    container.layer.shadowOpacity = 0.75;

    [self.rootVC.view addSubview:container];

    // ═══ 顶部装饰（现在会被clipsToBounds裁剪） ═══
    UIView *topGlow = [[UIView alloc] initWithFrame:CGRectMake(0, 0, w, 35)];
    CAGradientLayer *topGrad = [CAGradientLayer layer];
    topGrad.frame = topGlow.bounds;
    topGrad.colors = @[
        (id)[UIColor colorWithRed:0.12 green:0.60 blue:0.95 alpha:0.30].CGColor,
        (id)[UIColor colorWithRed:0.12 green:0.60 blue:0.95 alpha:0.0].CGColor,
    ];
    topGrad.startPoint = CGPointMake(0.5, 0);
    topGrad.endPoint = CGPointMake(0.5, 1);
    [topGlow.layer addSublayer:topGrad];
    [container addSubview:topGlow];

    // ═══ AI 图标（旋转90°顺时针）═══
    UILabel *iconLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 14, w, 32)];
    iconLabel.text = @"AI";
    iconLabel.textColor = [UIColor colorWithRed:0.12 green:0.65 blue:1.0 alpha:1.0];
    iconLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightBlack];
    iconLabel.textAlignment = NSTextAlignmentCenter;
    iconLabel.transform = CGAffineTransformMakeRotation(M_PI_2);
    [container addSubview:iconLabel];

    // ═══ 分隔线 ═══
    UIView *divider = [[UIView alloc] initWithFrame:CGRectMake(14, 54, w - 28, 0.8)];
    divider.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.15];
    [container addSubview:divider];

    // ═══ 状态指示器 ═══
    UIView *indicator = [[UIView alloc] initWithFrame:CGRectMake((w - 7) / 2, 66, 7, 7)];
    indicator.backgroundColor = [UIColor colorWithRed:0.12 green:0.65 blue:1.0 alpha:0.85];
    indicator.layer.cornerRadius = 3.5;
    indicator.layer.shadowColor = [UIColor colorWithRed:0.12 green:0.65 blue:1.0 alpha:1.0].CGColor;
    indicator.layer.shadowOffset = CGSizeZero;
    indicator.layer.shadowRadius = 3;
    indicator.layer.shadowOpacity = 0.95;
    self.statusIndicator = indicator;
    [container addSubview:indicator];

    // ═══ 文字容器（旋转区域） ═══
    UIView *textContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 82, w, h - 88)];
    textContainer.backgroundColor = [UIColor clearColor];

    // 创建文字label
    CGFloat textWidth = h - 88;
    self.displayLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, textWidth, w - 6)];
    self.displayLabel.textColor = [UIColor colorWithWhite:0.98 alpha:1.0];
    self.displayLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightMedium];
    self.displayLabel.numberOfLines = 1;
    self.displayLabel.textAlignment = NSTextAlignmentCenter;
    self.displayLabel.text = @"等待识别...";
    self.displayLabel.adjustsFontSizeToFitWidth = YES;
    self.displayLabel.minimumScaleFactor = 0.6;

    // 顺时针旋转90°
    self.displayLabel.transform = CGAffineTransformMakeRotation(M_PI_2);
    self.displayLabel.center = CGPointMake(textContainer.bounds.size.width / 2,
                                           textContainer.bounds.size.height / 2);

    [textContainer addSubview:self.displayLabel];
    [container addSubview:textContainer];

    // ═══ 拖动手势 ═══
    self.panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [container addGestureRecognizer:self.panGesture];

    // ═══ 游戏状态管理 ═══
    self.gameManager = [[GameStateManager alloc] init];
    __weak typeof(self) weakSelf = self;
    self.gameManager.onResultUpdate = ^(NSString *result) {
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.displayLabel.text = result;
            [weakSelf pulseIndicator];
        });
    };

    return self;
}

- (void)pulseIndicator {
    [self.statusIndicator.layer removeAllAnimations];

    CAKeyframeAnimation *scale = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
    scale.values = @[@1.0, @1.5, @1.0];
    scale.keyTimes = @[@0, @0.5, @1.0];
    scale.duration = 0.45;

    CAKeyframeAnimation *glow = [CAKeyframeAnimation animationWithKeyPath:@"shadowOpacity"];
    glow.values = @[@0.95, @1.0, @0.95];
    glow.keyTimes = @[@0, @0.5, @1.0];
    glow.duration = 0.45;

    CAAnimationGroup *group = [CAAnimationGroup animation];
    group.animations = @[scale, glow];
    group.duration = 0.45;

    [self.statusIndicator.layer addAnimation:group forKey:@"pulse"];
}

- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    CGRect screen = [UIScreen mainScreen].bounds;

    if (gesture.state == UIGestureRecognizerStateBegan) {
        self.initialY = self.frame.origin.y;
    }
    else if (gesture.state == UIGestureRecognizerStateChanged) {
        // 关键：相对于屏幕坐标空间计算translation
        CGFloat translation = [gesture translationInView:nil].y;
        CGFloat newY = self.initialY + translation;

        // 限制在屏幕范围内
        newY = MAX(0, MIN(newY, screen.size.height - self.frame.size.height));

        // 修改窗口 Y 坐标，X 保持在右边缘
        self.frame = CGRectMake(screen.size.width - self.frame.size.width,
                                newY,
                                self.frame.size.width,
                                self.frame.size.height);
    }
}

- (void)show {
    self.hidden = NO;
    [self makeKeyAndVisible];
    [self.gameManager startMonitoring];

    // 入场动画
    self.alpha = 0;
    self.transform = CGAffineTransformMakeTranslation(35, 0);
    [UIView animateWithDuration:0.4 delay:0 usingSpringWithDamping:0.75 initialSpringVelocity:0.5 options:0 animations:^{
        self.alpha = 1;
        self.transform = CGAffineTransformIdentity;
    } completion:nil];
}

- (void)hide {
    [self.gameManager stopMonitoring];

    [UIView animateWithDuration:0.25 animations:^{
        self.alpha = 0;
        self.transform = CGAffineTransformMakeTranslation(35, 0);
    } completion:^(BOOL finished) {
        self.hidden = YES;
        self.transform = CGAffineTransformIdentity;
    }];
}

@end
