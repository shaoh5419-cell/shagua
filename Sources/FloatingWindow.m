#import "FloatingWindow.h"
#import "GameStateManager.h"

@interface FloatingWindow ()
@property (nonatomic, strong) UILabel *displayLabel;
@property (nonatomic, strong) UIView *statusIndicator;
@property (nonatomic, strong) UIView *containerView;
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

    // 竖向侧边栏：宽56，高220
    CGFloat w = 56;
    CGFloat h = 220;

    // 贴紧右边缘，垂直居中
    CGFloat x = screen.size.width - w;
    CGFloat y = (screen.size.height - h) / 2;

    self = [super initWithFrame:CGRectMake(x, y, w, h)];
    if (!self) return nil;

    self.windowLevel = 10000010.0;
    self.backgroundColor = [UIColor clearColor];
    self.opaque = NO;
    self.userInteractionEnabled = YES;

    self.rootVC = [[UIViewController alloc] init];
    self.rootVC.view.backgroundColor = [UIColor clearColor];
    self.rootVC.view.userInteractionEnabled = YES;
    self.rootViewController = self.rootVC;

    // ═══ 主容器 ═══
    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, w, h)];
    container.backgroundColor = [UIColor colorWithRed:0.04 green:0.04 blue:0.09 alpha:0.96];
    container.layer.cornerRadius = w / 2;
    container.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMinXMaxYCorner;
    container.userInteractionEnabled = YES;
    self.containerView = container;

    // 边框渐变效果
    CAGradientLayer *border = [CAGradientLayer layer];
    border.frame = container.bounds;
    border.colors = @[
        (id)[UIColor colorWithRed:0.15 green:0.65 blue:1.0 alpha:0.5].CGColor,
        (id)[UIColor colorWithRed:0.10 green:0.45 blue:0.85 alpha:0.3].CGColor,
        (id)[UIColor colorWithRed:0.15 green:0.65 blue:1.0 alpha:0.5].CGColor,
    ];
    border.startPoint = CGPointMake(0.5, 0);
    border.endPoint = CGPointMake(0.5, 1);

    CAShapeLayer *borderMask = [CAShapeLayer layer];
    borderMask.path = [UIBezierPath bezierPathWithRoundedRect:container.bounds
                                            byRoundingCorners:UIRectCornerTopLeft | UIRectCornerBottomLeft
                                                  cornerRadii:CGSizeMake(w / 2, w / 2)].CGPath;
    borderMask.fillColor = [UIColor clearColor].CGColor;
    borderMask.strokeColor = [UIColor whiteColor].CGColor;
    borderMask.lineWidth = 1.5;
    border.mask = borderMask;
    [container.layer addSublayer:border];

    // 投影
    container.layer.shadowColor = [UIColor blackColor].CGColor;
    container.layer.shadowOffset = CGSizeMake(-3, 2);
    container.layer.shadowRadius = 10;
    container.layer.shadowOpacity = 0.7;

    [self.rootVC.view addSubview:container];

    // ═══ 顶部图标区 ═══
    // 顶部渐变装饰
    CAGradientLayer *topGlow = [CAGradientLayer layer];
    topGlow.frame = CGRectMake(0, 0, w, 28);
    topGlow.colors = @[
        (id)[UIColor colorWithRed:0.15 green:0.65 blue:1.0 alpha:0.25].CGColor,
        (id)[UIColor colorWithRed:0.15 green:0.65 blue:1.0 alpha:0.0].CGColor,
    ];
    topGlow.startPoint = CGPointMake(0.5, 0);
    topGlow.endPoint = CGPointMake(0.5, 1);
    [container.layer addSublayer:topGlow];

    UILabel *iconLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 12, w, 36)];
    iconLabel.text = @"AI";
    iconLabel.textColor = [UIColor colorWithRed:0.15 green:0.70 blue:1.0 alpha:1.0];
    iconLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightHeavy];
    iconLabel.textAlignment = NSTextAlignmentCenter;
    [container addSubview:iconLabel];

    // ═══ 状态指示器（中部） ═══
    UIView *indicator = [[UIView alloc] initWithFrame:CGRectMake((w - 6) / 2, 58, 6, 6)];
    indicator.backgroundColor = [UIColor colorWithRed:0.15 green:0.70 blue:1.0 alpha:0.8];
    indicator.layer.cornerRadius = 3;
    indicator.layer.shadowColor = [UIColor colorWithRed:0.15 green:0.70 blue:1.0 alpha:1.0].CGColor;
    indicator.layer.shadowOffset = CGSizeZero;
    indicator.layer.shadowRadius = 3;
    indicator.layer.shadowOpacity = 0.9;
    self.statusIndicator = indicator;
    [container addSubview:indicator];

    // ═══ 分隔线 ═══
    UIView *divider = [[UIView alloc] initWithFrame:CGRectMake(12, 72, w - 24, 0.5)];
    divider.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.12];
    [container addSubview:divider];

    // ═══ 文字容器（旋转区域） ═══
    UIView *textContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 82, w, h - 92)];
    textContainer.backgroundColor = [UIColor clearColor];
    textContainer.clipsToBounds = NO;

    // 创建文字label（旋转前的尺寸）
    CGFloat textWidth = h - 92;  // 旋转后会变成横向长度
    self.displayLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, textWidth, w - 8)];
    self.displayLabel.textColor = [UIColor colorWithWhite:0.97 alpha:1.0];
    self.displayLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    self.displayLabel.numberOfLines = 1;
    self.displayLabel.textAlignment = NSTextAlignmentCenter;
    self.displayLabel.text = @"等待识别...";
    self.displayLabel.adjustsFontSizeToFitWidth = YES;
    self.displayLabel.minimumScaleFactor = 0.7;

    // 顺时针旋转90°
    self.displayLabel.transform = CGAffineTransformMakeRotation(M_PI_2);
    self.displayLabel.center = CGPointMake(textContainer.bounds.size.width / 2,
                                           textContainer.bounds.size.height / 2);

    [textContainer addSubview:self.displayLabel];
    [container addSubview:textContainer];

    // ═══ 拖动手势（修复：直接添加到window的rootVC.view） ═══
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [self.rootVC.view addGestureRecognizer:pan];

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
    // 脉冲动画：缩放+发光
    [self.statusIndicator.layer removeAllAnimations];

    CAKeyframeAnimation *scale = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
    scale.values = @[@1.0, @1.6, @1.0];
    scale.keyTimes = @[@0, @0.5, @1.0];
    scale.duration = 0.5;

    CAKeyframeAnimation *glow = [CAKeyframeAnimation animationWithKeyPath:@"shadowOpacity"];
    glow.values = @[@0.9, @1.0, @0.9];
    glow.keyTimes = @[@0, @0.5, @1.0];
    glow.duration = 0.5;

    CAAnimationGroup *group = [CAAnimationGroup animation];
    group.animations = @[scale, glow];
    group.duration = 0.5;

    [self.statusIndicator.layer addAnimation:group forKey:@"pulse"];
}

- (void)show {
    self.hidden = NO;
    [self makeKeyAndVisible];
    [self.gameManager startMonitoring];

    // 入场动画
    self.alpha = 0;
    self.transform = CGAffineTransformMakeTranslation(40, 0);
    [UIView animateWithDuration:0.45 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:0.6 options:0 animations:^{
        self.alpha = 1;
        self.transform = CGAffineTransformIdentity;
    } completion:nil];
}

- (void)hide {
    [self.gameManager stopMonitoring];

    [UIView animateWithDuration:0.3 animations:^{
        self.alpha = 0;
        self.transform = CGAffineTransformMakeTranslation(40, 0);
    } completion:^(BOOL finished) {
        self.hidden = YES;
        self.transform = CGAffineTransformIdentity;
    }];
}

// 修复：只允许垂直拖动，x锁定在右边缘
- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    static CGPoint lastTranslation = {0, 0};

    if (gesture.state == UIGestureRecognizerStateBegan) {
        lastTranslation = CGPointZero;
    }

    CGPoint translation = [gesture translationInView:self.rootVC.view];
    CGFloat deltaY = translation.y - lastTranslation.y;
    lastTranslation = translation;

    CGRect screen = [UIScreen mainScreen].bounds;
    CGRect frame = self.frame;

    // 只改变y坐标
    frame.origin.y += deltaY;
    frame.origin.y = MAX(0, MIN(frame.origin.y, screen.size.height - frame.size.height));

    // x始终锁定在右边缘
    frame.origin.x = screen.size.width - frame.size.width;

    self.frame = frame;

    if (gesture.state == UIGestureRecognizerStateEnded || gesture.state == UIGestureRecognizerStateCancelled) {
        lastTranslation = CGPointZero;
    }
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    // 确保整个窗口区域都能接收触摸
    return CGRectContainsPoint(self.bounds, point);
}

@end
