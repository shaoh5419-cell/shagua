#import "LogWindow.h"

@interface LogWindow ()
@property (nonatomic, strong) UITextView *logView;
@property (nonatomic, strong) UIViewController *rootVC;
@property (nonatomic, strong) NSMutableString *logBuffer;
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

    self.logBuffer = [NSMutableString string];
    self.windowLevel = 10000020.0;
    self.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:0.95];

    self.rootVC = [[UIViewController alloc] init];
    self.rootVC.view.backgroundColor = [UIColor clearColor];
    self.rootViewController = self.rootVC;

    // 日志文本框
    self.logView = [[UITextView alloc] initWithFrame:CGRectMake(0, 35, frame.size.width, frame.size.height - 35)];
    self.logView.backgroundColor = [UIColor colorWithRed:0.05 green:0.05 blue:0.05 alpha:1.0];
    self.logView.textColor = [UIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:1.0];
    self.logView.font = [UIFont systemFontOfSize:9];
    self.logView.editable = NO;
    self.logView.scrollEnabled = YES;
    [self.rootVC.view addSubview:self.logView];

    // 工具栏背景
    UIView *toolbar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, 35)];
    toolbar.backgroundColor = [UIColor colorWithRed:0.08 green:0.08 blue:0.08 alpha:1.0];
    [self.rootVC.view addSubview:toolbar];

    // 关闭按钮
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    closeBtn.frame = CGRectMake(frame.size.width - 40, 5, 35, 25);
    closeBtn.backgroundColor = [UIColor colorWithRed:1.0 green:0.2 blue:0.2 alpha:0.8];
    closeBtn.layer.cornerRadius = 4;
    [closeBtn setTitle:@"关闭" forState:UIControlStateNormal];
    closeBtn.titleLabel.font = [UIFont systemFontOfSize:10];
    [closeBtn addTarget:self action:@selector(hide) forControlEvents:UIControlEventTouchUpInside];
    [toolbar addSubview:closeBtn];

    // 清空按钮
    UIButton *clearBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    clearBtn.frame = CGRectMake(frame.size.width - 85, 5, 35, 25);
    clearBtn.backgroundColor = [UIColor colorWithRed:0.2 green:0.2 blue:1.0 alpha:0.8];
    clearBtn.layer.cornerRadius = 4;
    [clearBtn setTitle:@"清空" forState:UIControlStateNormal];
    clearBtn.titleLabel.font = [UIFont systemFontOfSize:10];
    [clearBtn addTarget:self action:@selector(clearLog) forControlEvents:UIControlEventTouchUpInside];
    [toolbar addSubview:clearBtn];

    // 标题
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 5, 100, 25)];
    titleLabel.text = @"实时日志";
    titleLabel.textColor = [UIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:1.0];
    titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightBold];
    [toolbar addSubview:titleLabel];

    [self addLog:@"日志窗口已初始化"];

    return self;
}

- (void)addLog:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *timestamp = [self getCurrentTimestamp];
        NSString *logLine = [NSString stringWithFormat:@"[%@] %@\n", timestamp, message];

        [self.logBuffer appendString:logLine];
        self.logView.text = self.logBuffer;

        // 自动滚动到底部
        if (self.logView.text.length > 0) {
            [self.logView scrollRangeToVisible:NSMakeRange(self.logView.text.length - 1, 1)];
        }
    });
}

- (void)clearLog {
    [self.logBuffer setString:@""];
    self.logView.text = @"";
    [self addLog:@"日志已清空"];
}

- (NSString *)getCurrentTimestamp {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"HH:mm:ss.SSS";
    return [formatter stringFromDate:[NSDate date]];
}

- (void)show {
    self.hidden = NO;
    [self makeKeyAndVisible];
    [self addLog:@"日志窗口已显示"];
}

- (void)hide {
    self.hidden = YES;
}

@end
