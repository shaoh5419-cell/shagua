#import "DebugWindow.h"

@interface DebugWindow ()
@property (nonatomic, strong) UITextView *logView;
@property (nonatomic, strong) UIButton *closeButton;
@end

@implementation DebugWindow

+ (instancetype)shared {
    static DebugWindow *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[DebugWindow alloc] init];
    });
    return instance;
}

- (instancetype)init {
    CGRect screen = [UIScreen mainScreen].bounds;
    CGFloat w = screen.size.width * 0.8;
    CGFloat h = screen.size.height * 0.6;
    CGFloat x = (screen.size.width - w) / 2;
    CGFloat y = (screen.size.height - h) / 2;

    self = [super initWithFrame:CGRectMake(x, y, w, h)];
    if (!self) return nil;

    self.windowLevel = 10000020.0;
    self.backgroundColor = [UIColor clearColor];
    self.hidden = YES;

    UIViewController *vc = [[UIViewController alloc] init];
    vc.view.backgroundColor = [UIColor clearColor];
    self.rootViewController = vc;

    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, w, h)];
    container.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.95];
    container.layer.cornerRadius = 12;
    [vc.view addSubview:container];

    self.logView = [[UITextView alloc] initWithFrame:CGRectMake(10, 40, w - 20, h - 60)];
    self.logView.backgroundColor = [UIColor blackColor];
    self.logView.textColor = [UIColor greenColor];
    self.logView.font = [UIFont fontWithName:@"Courier" size:10];
    self.logView.editable = NO;
    [container addSubview:self.logView];

    self.closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.closeButton.frame = CGRectMake(w - 50, 5, 40, 30);
    [self.closeButton setTitle:@"关闭" forState:UIControlStateNormal];
    [self.closeButton addTarget:self action:@selector(hide) forControlEvents:UIControlEventTouchUpInside];
    [container addSubview:self.closeButton];

    return self;
}

- (void)log:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *timestamp = [NSDateFormatter localizedStringFromDate:[NSDate date] dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterMediumStyle];
        NSString *logLine = [NSString stringWithFormat:@"[%@] %@\n", timestamp, message];
        self.logView.text = [self.logView.text stringByAppendingString:logLine];

        NSRange bottom = NSMakeRange(self.logView.text.length - 1, 1);
        [self.logView scrollRangeToVisible:bottom];
    });
}

- (void)show {
    self.hidden = NO;
    [self makeKeyAndVisible];
}

- (void)hide {
    self.hidden = YES;
}

- (void)clear {
    self.logView.text = @"";
}

@end
