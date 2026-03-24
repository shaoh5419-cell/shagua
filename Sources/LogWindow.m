#import "LogWindow.h"

@interface LogWindow ()
@property (nonatomic, strong) UITextView *logView;
@property (nonatomic, strong) UIViewController *rootVC;
@end

@implementation LogWindow

+ (instancetype)shared {
    static LogWindow *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        CGRect screen = [UIScreen mainScreen].bounds;
        instance = [[self alloc] initWithFrame:CGRectMake(0, 0, screen.size.width, screen.size.height * 0.4)];
    });
    return instance;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) return nil;

    self.windowLevel = 10000020.0;
    self.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:0.95];

    self.rootVC = [[UIViewController alloc] init];
    self.rootVC.view.backgroundColor = [UIColor clearColor];
    self.rootViewController = self.rootVC;

    // 日志文本框
    self.logView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
    self.logView.backgroundColor = [UIColor colorWithRed:0.05 green:0.05 blue:0.05 alpha:1.0];
    self.logView.textColor = [UIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:1.0];
    self.logView.font = [UIFont systemFontOfSize:10];
    self.logView.editable = NO;
    self.logView.scrollEnabled = YES;
    [self.rootVC.view addSubview:self.logView];

    // 关闭按钮
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    closeBtn.frame = CGRectMake(frame.size.width - 40, 5, 35, 25);
    closeBtn.backgroundColor = [UIColor colorWithRed:1.0 green:0.2 blue:0.2 alpha:0.8];
    closeBtn.layer.cornerRadius = 4;
    [closeBtn setTitle:@"关闭" forState:UIControlStateNormal];
    closeBtn.titleLabel.font = [UIFont systemFontOfSize:10];
    [closeBtn addTarget:self action:@selector(hide) forControlEvents:UIControlEventTouchUpInside];
    [self.rootVC.view addSubview:closeBtn];

    // 清空按钮
    UIButton *clearBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    clearBtn.frame = CGRectMake(frame.size.width - 85, 5, 35, 25);
    clearBtn.backgroundColor = [UIColor colorWithRed:0.2 green:0.2 blue:1.0 alpha:0.8];
    clearBtn.layer.cornerRadius = 4;
    [clearBtn setTitle:@"清空" forState:UIControlStateNormal];
    clearBtn.titleLabel.font = [UIFont systemFontOfSize:10];
    [clearBtn addTarget:self action:@selector(clearLog) forControlEvents:UIControlEventTouchUpInside];
    [self.rootVC.view addSubview:clearBtn];

    return self;
}

- (void)addLog:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *timestamp = [self getCurrentTimestamp];
        NSString *logLine = [NSString stringWithFormat:@"[%@] %@\n", timestamp, message];
        self.logView.text = [self.logView.text stringByAppendingString:logLine];

        // 自动滚动到底部
        [self.logView scrollRangeToVisible:NSMakeRange(self.logView.text.length - 1, 1)];
    });
}

- (void)clearLog {
    self.logView.text = @"";
}

- (NSString *)getCurrentTimestamp {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"HH:mm:ss.SSS";
    return [formatter stringFromDate:[NSDate date]];
}

- (void)show {
    self.hidden = NO;
    [self makeKeyAndVisible];
}

- (void)hide {
    self.hidden = YES;
}

@end
