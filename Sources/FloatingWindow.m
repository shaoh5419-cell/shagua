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
    CGFloat w = 200;
    CGFloat h = 68;

    // 横屏左旋（home在左）时，portrait右侧 = landscape右侧上方
    // 初始位置：portrait右边缘，垂直居中偏上；可拖动调整
    CGFloat x = screen.size.width - w - 10;
    CGFloat y = screen.size.height * 0.35 - h / 2;

    self = [super initWithFrame:CGRectMake(x, y, w, h)];
    if (!self) return nil;

    self.windowLevel = 10000010.0;
    self.backgroundColor = [UIColor clearColor];
    self.opaque = NO;

    self.rootVC = [[UIViewController alloc] init];
    self.rootVC.view.backgroundColor = [UIColor clearColor];
    self.rootViewController = self.rootVC;

    // 主背景：深色磨砂胶囊
    UIView *bg = [[UIView alloc] initWithFrame:CGRectMake(0, 0, w, h)];
    bg.backgroundColor = [UIColor colorWithRed:0.06 green:0.06 blue:0.10 alpha:0.92];
    bg.layer.cornerRadius = h / 2;
    bg.layer.borderWidth = 1.0;
    bg.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.10].CGColor;
    // 投影
    bg.layer.shadowColor = [UIColor blackColor].CGColor;
    bg.layer.shadowOffset = CGSizeMake(0, 4);
    bg.layer.shadowRadius = 10;
    bg.layer.shadowOpacity = 0.5;
    [self.rootVC.view addSubview:bg];

    // 左侧彩色指示条
    UIView *stripe = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 4, h)];
    stripe.backgroundColor = [UIColor colorWithRed:0.20 green:0.75 blue:1.0 alpha:1.0];
    // 左侧胶囊圆角裁剪
    UIView *stripeWrap = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 16, h)];
    stripeWrap.clipsToBounds = YES;
    stripeWrap.layer.cornerRadius = h / 2;
    stripeWrap.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMinXMaxYCorner;
    [stripeWrap addSubview:stripe];
    [bg addSubview:stripeWrap];

    // "AI" 小标签
    UILabel *aiLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, 28, h)];
    aiLabel.text = @"AI";
    aiLabel.textColor = [UIColor colorWithRed:0.20 green:0.75 blue:1.0 alpha:1.0];
    aiLabel.font = [UIFont boldSystemFontOfSize:11];
    aiLabel.textAlignment = NSTextAlignmentCenter;
    [bg addSubview:aiLabel];

    // 分隔线
    UIView *sep = [[UIView alloc] initWithFrame:CGRectMake(38, 12, 1, h - 24)];
    sep.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.12];
    [bg addSubview:sep];

    // 主文本标签
    self.displayLabel = [[UILabel alloc] initWithFrame:CGRectMake(46, 0, w - 54, h)];
    self.displayLabel.textColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    self.displayLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    self.displayLabel.numberOfLines = 2;
    self.displayLabel.textAlignment = NSTextAlignmentLeft;
    self.displayLabel.text = @"等待识别...";
    [bg addSubview:self.displayLabel];

    // 拖动手势
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [bg addGestureRecognizer:pan];

    // 游戏状态管理
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

- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    CGPoint delta = [gesture translationInView:self];
    CGRect screen = [UIScreen mainScreen].bounds;
    CGPoint c = self.center;
    c.x = MAX(self.frame.size.width / 2, MIN(c.x + delta.x, screen.size.width - self.frame.size.width / 2));
    c.y = MAX(self.frame.size.height / 2, MIN(c.y + delta.y, screen.size.height - self.frame.size.height / 2));
    self.center = c;
    [gesture setTranslation:CGPointZero inView:self];
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    return YES;
}

@end
