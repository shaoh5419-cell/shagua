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

    // 竖向窄条：宽64，高240
    CGFloat w = 64;
    CGFloat h = 240;

    // 贴紧 portrait 右边缘，垂直居中
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

    // ═══ 背景容器 ═══
    UIView *bg = [[UIView alloc] initWithFrame:CGRectMake(0, 0, w, h)];
    bg.backgroundColor = [UIColor colorWithRed:0.05 green:0.05 blue:0.10 alpha:0.95];
    bg.layer.cornerRadius = w / 2;
    bg.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMinXMaxYCorner;
    bg.layer.borderWidth = 1.2;
    bg.layer.borderColor = [UIColor colorWithRed:0.18 green:0.72 blue:1.0 alpha:0.35].CGColor;

    // 内发光效果
    bg.layer.shadowColor = [UIColor colorWithRed:0.18 green:0.72 blue:1.0 alpha:1.0].CGColor;
    bg.layer.shadowOffset = CGSizeZero;
    bg.layer.shadowRadius = 4;
    bg.layer.shadowOpacity = 0.15;

    // 外投影
    CALayer *shadowLayer = [CALayer layer];
    shadowLayer.frame = bg.bounds;
    shadowLayer.cornerRadius = w / 2;
    shadowLayer.shadowColor = [UIColor blackColor].CGColor;
    shadowLayer.shadowOffset = CGSizeMake(-2, 3);
    shadowLayer.shadowRadius = 8;
    shadowLayer.shadowOpacity = 0.6;
    shadowLayer.backgroundColor = [UIColor clearColor].CGColor;
    [self.rootVC.view.layer insertSublayer:shadowLayer atIndex:0];

    [self.rootVC.view addSubview:bg];

    // ═══ 顶部装饰带（渐变） ═══
    UIView *topWrap = [[UIView alloc] initWithFrame:CGRectMake(0, 0, w, 20)];
    topWrap.clipsToBounds = YES;
    topWrap.layer.cornerRadius = w / 2;
    topWrap.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;

    CAGradientLayer *topGrad = [CAGradientLayer layer];
    topGrad.frame = CGRectMake(0, 0, w, 5);
    topGrad.colors = @[
        (id)[UIColor colorWithRed:0.18 green:0.72 blue:1.0 alpha:0.9].CGColor,
        (id)[UIColor colorWithRed:0.10 green:0.50 blue:0.85 alpha:0.7].CGColor,
    ];
    topGrad.startPoint = CGPointMake(0, 0);
    topGrad.endPoint = CGPointMake(1, 0);
    [topWrap.layer addSublayer:topGrad];
    [bg addSubview:topWrap];

    // ═══ AI 图标标签 ═══
    UILabel *aiLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 18, w, 32)];
    aiLabel.text = @"AI";
    aiLabel.textColor = [UIColor colorWithRed:0.20 green:0.75 blue:1.0 alpha:1.0];
    aiLabel.font = [UIFont boldSystemFontOfSize:16];
    aiLabel.textAlignment = NSTextAlignmentCenter;
    [bg addSubview:aiLabel];

    // ═══ 分隔线 ═══
    UIView *sep1 = [[UIView alloc] initWithFrame:CGRectMake(14, 52, w - 28, 1)];
    sep1.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.10];
    [bg addSubview:sep1];

    // ═══ 状态指示点 ═══
    UIView *dot = [[UIView alloc] initWithFrame:CGRectMake((w - 10) / 2, 64, 10, 10)];
    dot.layer.cornerRadius = 5;
    dot.backgroundColor = [UIColor colorWithRed:0.18 green:0.72 blue:1.0 alpha:0.7];
    dot.layer.shadowColor = [UIColor colorWithRed:0.18 green:0.72 blue:1.0 alpha:1.0].CGColor;
    dot.layer.shadowOffset = CGSizeZero;
    dot.layer.shadowRadius = 4;
    dot.layer.shadowOpacity = 0.8;
    self.indicatorDot = dot;
    [bg addSubview:dot];

    // ═══ 文字区域（旋转90°以适配横屏阅读） ═══
    // 在portrait坐标系中，文字容器高150（变成横屏的"宽度"）
    UIView *textContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 80, w, 150)];
    textContainer.backgroundColor = [UIColor clearColor];

    // 创建label，宽度150（横屏时的文字行长）
    self.displayLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 150, w)];
    self.displayLabel.textColor = [UIColor colorWithWhite:0.96 alpha:1.0];
    self.displayLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightMedium];
    self.displayLabel.numberOfLines = 1;
    self.displayLabel.textAlignment = NSTextAlignmentCenter;
    self.displayLabel.text = @"等待识别...";

    // 旋转90°（顺时针），横屏时文字从左到右正常阅读
    self.displayLabel.transform = CGAffineTransformMakeRotation(M_PI_2);
    self.displayLabel.center = CGPointMake(textContainer.bounds.size.width / 2,
                                           textContainer.bounds.size.height / 2);
    [textContainer addSubview:self.displayLabel];
    [bg addSubview:textContainer];

    // ═══ 底部分隔线 ═══
    UIView *sep2 = [[UIView alloc] initWithFrame:CGRectMake(14, h - 10, w - 28, 1)];
    sep2.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.08];
    [bg addSubview:sep2];

    // ═══ 拖动手势（仅 y 轴） ═══
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [bg addGestureRecognizer:pan];

    // ═══ 游戏状态管理 ═══
    self.gameManager = [[GameStateManager alloc] init];
    __weak typeof(self) weakSelf = self;
    self.gameManager.onResultUpdate = ^(NSString *result) {
        dispatch_async(dispatch_get_main_queue(), ^{
            // 直接显示结果内容
            weakSelf.displayLabel.text = result;

            // 指示点脉冲动画
            [weakSelf pulseIndicator];
        });
    };

    return self;
}

- (void)pulseIndicator {
    // 移除旧动画
    [self.indicatorDot.layer removeAllAnimations];

    // 缩放+透明度脉冲
    CAKeyframeAnimation *pulse = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
    pulse.values = @[@1.0, @1.4, @1.0];
    pulse.keyTimes = @[@0, @0.5, @1.0];
    pulse.duration = 0.4;

    CAKeyframeAnimation *fade = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
    fade.values = @[@0.7, @1.0, @0.7];
    fade.keyTimes = @[@0, @0.5, @1.0];
    fade.duration = 0.4;

    CAAnimationGroup *group = [CAAnimationGroup animation];
    group.animations = @[pulse, fade];
    group.duration = 0.4;

    [self.indicatorDot.layer addAnimation:group forKey:@"pulse"];
}

- (void)show {
    self.hidden = NO;
    [self makeKeyAndVisible];
    [self.gameManager startMonitoring];

    // 入场动画
    self.alpha = 0;
    self.transform = CGAffineTransformMakeTranslation(30, 0);
    [UIView animateWithDuration:0.4 delay:0 usingSpringWithDamping:0.75 initialSpringVelocity:0.5 options:0 animations:^{
        self.alpha = 1;
        self.transform = CGAffineTransformIdentity;
    } completion:nil];
}

- (void)hide {
    [self.gameManager stopMonitoring];

    // 退场动画
    [UIView animateWithDuration:0.25 animations:^{
        self.alpha = 0;
        self.transform = CGAffineTransformMakeTranslation(30, 0);
    } completion:^(BOOL finished) {
        self.hidden = YES;
        self.transform = CGAffineTransformIdentity;
    }];
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
