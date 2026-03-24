#import "RootViewController.h"
#import <spawn.h>
#import <sys/wait.h>
#import <mach-o/dyld.h>
#import <signal.h>
#import <errno.h>
#import "PersonaHelpers.h"
#import "LogWindow.h"

extern char **environ;

#define PID_FILE "/var/mobile/Library/Caches/com.ddz.helper.pid"

@interface RootViewController ()
@property (nonatomic, strong) UIButton *startButton;
@property (nonatomic, assign) BOOL isRunning;
// 视觉层引用
@property (nonatomic, weak) CAGradientLayer *buttonGradient;
@property (nonatomic, weak) CALayer *glowLayer;
@property (nonatomic, weak) UIView *buttonShell;
@property (nonatomic, weak) UIView *statusDot;
@property (nonatomic, weak) UILabel *statusLabel;
@end

@implementation RootViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // ── 背景：深空渐变 ──
    self.view.backgroundColor = [UIColor colorWithRed:0.04 green:0.04 blue:0.08 alpha:1.0];
    CAGradientLayer *bg = [CAGradientLayer layer];
    bg.frame = self.view.bounds;
    bg.colors = @[
        (id)[UIColor colorWithRed:0.08 green:0.08 blue:0.16 alpha:1.0].CGColor,
        (id)[UIColor colorWithRed:0.02 green:0.02 blue:0.05 alpha:1.0].CGColor,
    ];
    bg.startPoint = CGPointMake(0.5, 0.0);
    bg.endPoint   = CGPointMake(0.5, 1.0);
    [self.view.layer insertSublayer:bg atIndex:0];

    CGFloat cx = self.view.bounds.size.width / 2;
    CGFloat cy = self.view.bounds.size.height / 2;

    // ── 应用标题 ──
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = @"AI  助  手";
    titleLabel.textColor = [UIColor colorWithWhite:0.55 alpha:1.0];
    titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [titleLabel sizeToFit];
    titleLabel.center = CGPointMake(cx, 70);
    [self.view addSubview:titleLabel];

    // ── 光晕环（active时发光）──
    UIView *glowRing = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 210, 210)];
    glowRing.center = CGPointMake(cx, cy - 10);
    glowRing.backgroundColor = [UIColor clearColor];
    glowRing.layer.cornerRadius = 105;
    CALayer *glow = [CALayer layer];
    glow.frame = glowRing.bounds;
    glow.cornerRadius = 105;
    glow.backgroundColor = [UIColor clearColor].CGColor;
    glow.shadowColor = [UIColor colorWithRed:0.10 green:0.88 blue:0.38 alpha:1.0].CGColor;
    glow.shadowOffset = CGSizeZero;
    glow.shadowRadius = 28;
    glow.shadowOpacity = 0;
    [glowRing.layer addSublayer:glow];
    self.glowLayer = glow;
    [self.view addSubview:glowRing];

    // ── 按钮底座（外壳 / bezel）──
    UIView *shell = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 180, 180)];
    shell.center = CGPointMake(cx, cy - 10);
    shell.layer.cornerRadius = 90;
    shell.backgroundColor = [UIColor colorWithWhite:0.07 alpha:1.0];
    shell.layer.borderWidth = 1.5;
    shell.layer.borderColor = [UIColor colorWithWhite:0.18 alpha:1.0].CGColor;
    // 底部投影（立体感）
    shell.layer.shadowColor = [UIColor blackColor].CGColor;
    shell.layer.shadowOffset = CGSizeMake(0, 10);
    shell.layer.shadowRadius = 20;
    shell.layer.shadowOpacity = 0.75;
    self.buttonShell = shell;
    [self.view addSubview:shell];

    // ── 按钮面板 ──
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectMake(10, 10, 160, 160);
    btn.layer.cornerRadius = 80;
    btn.clipsToBounds = YES;

    // 渐变层（颜色随状态改变）
    CAGradientLayer *grad = [CAGradientLayer layer];
    grad.frame = btn.bounds;
    grad.cornerRadius = 80;
    grad.startPoint = CGPointMake(0.5, 0.0);
    grad.endPoint   = CGPointMake(0.5, 1.0);
    [btn.layer insertSublayer:grad atIndex:0];
    self.buttonGradient = grad;

    // 顶部高光（仿真凸面反光）
    UIView *highlight = [[UIView alloc] initWithFrame:CGRectMake(20, 8, 120, 55)];
    highlight.layer.cornerRadius = 27;
    CAGradientLayer *hlGrad = [CAGradientLayer layer];
    hlGrad.frame = highlight.bounds;
    hlGrad.cornerRadius = 27;
    hlGrad.colors = @[
        (id)[UIColor colorWithWhite:1.0 alpha:0.10].CGColor,
        (id)[UIColor colorWithWhite:1.0 alpha:0.00].CGColor,
    ];
    hlGrad.startPoint = CGPointMake(0.5, 0.0);
    hlGrad.endPoint   = CGPointMake(0.5, 1.0);
    [highlight.layer addSublayer:hlGrad];
    [btn addSubview:highlight];

    btn.titleLabel.font = [UIFont boldSystemFontOfSize:32];
    [btn addTarget:self action:@selector(onTouchDown)    forControlEvents:UIControlEventTouchDown];
    [btn addTarget:self action:@selector(onTouchUp)      forControlEvents:UIControlEventTouchUpOutside | UIControlEventTouchCancel];
    [btn addTarget:self action:@selector(onButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    self.startButton = btn;
    [shell addSubview:btn];

    // ── 状态指示点 ──
    UIView *dot = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 8, 8)];
    dot.layer.cornerRadius = 4;
    dot.center = CGPointMake(cx - 30, cy + 115);
    self.statusDot = dot;
    [self.view addSubview:dot];

    // ── 状态文字 ──
    UILabel *stLbl = [[UILabel alloc] init];
    stLbl.font = [UIFont systemFontOfSize:13 weight:UIFontWeightRegular];
    stLbl.textAlignment = NSTextAlignmentLeft;
    [self.view addSubview:stLbl];
    self.statusLabel = stLbl;

    // ── 初始化状态 ──
    self.isRunning = [self isHUDRunning];
    [self refreshVisuals:NO];

    // ── 日志按钮 ──
    UIButton *logBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    logBtn.frame = CGRectMake(20, self.view.bounds.size.height - 50, 60, 35);
    logBtn.backgroundColor = [UIColor colorWithRed:0.2 green:0.6 blue:0.2 alpha:0.8];
    logBtn.layer.cornerRadius = 6;
    [logBtn setTitle:@"日志" forState:UIControlStateNormal];
    logBtn.titleLabel.font = [UIFont systemFontOfSize:12];
    [logBtn addTarget:self action:@selector(showLogWindow) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:logBtn];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // 每次界面出现时重新检测，避免后台期间状态变化
    BOOL running = [self isHUDRunning];
    if (running != self.isRunning) {
        self.isRunning = running;
        [self refreshVisuals:NO];
    }
}

#pragma mark - HUD 检测

- (BOOL)isHUDRunning {
    NSString *pidStr = [NSString stringWithContentsOfFile:@(PID_FILE)
                                                 encoding:NSUTF8StringEncoding
                                                    error:nil];
    if (!pidStr) return NO;
    pid_t pid = (pid_t)[pidStr intValue];
    if (pid <= 0) return NO;
    int rc = kill(pid, 0);
    // rc==0: 进程存在且有权限
    // rc==-1 EPERM: 进程存在但无权（HUD以root运行，本进程为mobile，正常现象）
    // rc==-1 ESRCH: 进程不存在
    return (rc == 0 || (rc == -1 && errno == EPERM));
}

#pragma mark - 按钮交互

- (void)onTouchDown {
    [UIView animateWithDuration:0.08 animations:^{
        self.buttonShell.transform = CGAffineTransformMakeScale(0.94, 0.94);
    }];
    UIImpactFeedbackGenerator *hap = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
    [hap impactOccurred];
}

- (void)onTouchUp {
    [UIView animateWithDuration:0.15 delay:0 usingSpringWithDamping:0.6 initialSpringVelocity:0.5 options:0 animations:^{
        self.buttonShell.transform = CGAffineTransformIdentity;
    } completion:nil];
}

- (void)onButtonTapped {
    [self onTouchUp];
    if (!self.isRunning) {
        [self startHUD];
    } else {
        [self stopHUD];
    }
}

#pragma mark - 启动 / 停止

- (void)startHUD {
    [[LogWindow shared] addLog:@"startHUD 被调用"];

    // 防止重复启动：如果进程已存在则只刷新状态
    if ([self isHUDRunning]) {
        [[LogWindow shared] addLog:@"HUD 已在运行"];
        self.isRunning = YES;
        [self refreshVisuals:NO];
        return;
    }

    [[LogWindow shared] addLog:@"开始启动 HUD 进程"];

    NSString *plistPath = @"/Library/LaunchDaemons/com.ddz.helper.daemon.plist";
    BOOL usesDaemon = [[NSFileManager defaultManager] fileExistsAtPath:plistPath];

    [[LogWindow shared] addLog:[NSString stringWithFormat:@"使用 Daemon: %@", usesDaemon ? @"是" : @"否"]];

    posix_spawnattr_t attr;
    posix_spawnattr_init(&attr);
    posix_spawnattr_set_persona_np(&attr, 99, POSIX_SPAWN_PERSONA_FLAGS_OVERRIDE);
    posix_spawnattr_set_persona_uid_np(&attr, 0);
    posix_spawnattr_set_persona_gid_np(&attr, 0);

    pid_t task_pid;
    int rc;

    if (usesDaemon) {
        static const char *launchctl = "/usr/bin/launchctl";
        const char *args[] = {launchctl, "load", [plistPath UTF8String], NULL};
        rc = posix_spawn(&task_pid, launchctl, NULL, &attr, (char **)args, environ);
        posix_spawnattr_destroy(&attr);
        if (rc == 0) { int s; waitpid(task_pid, &s, 0); }
    } else {
        posix_spawnattr_setpgroup(&attr, 0);
        posix_spawnattr_setflags(&attr, POSIX_SPAWN_SETPGROUP);

        uint32_t size = 0;
        _NSGetExecutablePath(NULL, &size);
        char *execPath = (char *)malloc(size);
        _NSGetExecutablePath(execPath, &size);

        [[LogWindow shared] addLog:[NSString stringWithFormat:@"执行路径: %s", execPath]];

        const char *args[] = {execPath, "-hud", NULL};
        rc = posix_spawn(&task_pid, execPath, NULL, &attr, (char **)args, environ);
        posix_spawnattr_destroy(&attr);
        free(execPath);

        if (rc == 0) {
            int unused;
            waitpid(task_pid, &unused, WNOHANG);
        }
    }

    if (rc == 0) {
        [[LogWindow shared] addLog:[NSString stringWithFormat:@"HUD 进程启动成功, PID: %d", task_pid]];
        self.isRunning = YES;
        [self refreshVisuals:YES];
    } else {
        [[LogWindow shared] addLog:[NSString stringWithFormat:@"HUD 进程启动失败: %s", strerror(rc)]];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"启动失败"
            message:[NSString stringWithFormat:@"错误码: %d (%s)", rc, strerror(rc)]
            preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)stopHUD {
    NSString *plistPath = @"/Library/LaunchDaemons/com.ddz.helper.daemon.plist";
    BOOL usesDaemon = [[NSFileManager defaultManager] fileExistsAtPath:plistPath];

    posix_spawnattr_t attr;
    posix_spawnattr_init(&attr);
    posix_spawnattr_set_persona_np(&attr, 99, POSIX_SPAWN_PERSONA_FLAGS_OVERRIDE);
    posix_spawnattr_set_persona_uid_np(&attr, 0);
    posix_spawnattr_set_persona_gid_np(&attr, 0);

    pid_t task_pid;

    if (usesDaemon) {
        static const char *launchctl = "/usr/bin/launchctl";
        const char *args[] = {launchctl, "unload", [plistPath UTF8String], NULL};
        posix_spawn(&task_pid, launchctl, NULL, &attr, (char **)args, environ);
        posix_spawnattr_destroy(&attr);
        int s; waitpid(task_pid, &s, 0);
    } else {
        uint32_t size = 0;
        _NSGetExecutablePath(NULL, &size);
        char *execPath = (char *)malloc(size);
        _NSGetExecutablePath(execPath, &size);

        const char *args[] = {execPath, "-exit", NULL};
        posix_spawn(&task_pid, execPath, NULL, &attr, (char **)args, environ);
        posix_spawnattr_destroy(&attr);
        free(execPath);
        int s; waitpid(task_pid, &s, 0);
    }

    self.isRunning = NO;
    [self refreshVisuals:YES];
}

#pragma mark - 视觉刷新

- (void)refreshVisuals:(BOOL)animated {
    void (^update)(void) = ^{
        if (self.isRunning) {
            // 绿色激活态
            self.buttonGradient.colors = @[
                (id)[UIColor colorWithRed:0.12 green:0.92 blue:0.42 alpha:1.0].CGColor,
                (id)[UIColor colorWithRed:0.06 green:0.62 blue:0.26 alpha:1.0].CGColor,
            ];
            [self.startButton setTitle:@"关闭" forState:UIControlStateNormal];
            [self.startButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            self.buttonShell.layer.borderColor = [UIColor colorWithRed:0.10 green:0.80 blue:0.38 alpha:0.4].CGColor;
            self.glowLayer.shadowOpacity = 0.65;
            self.statusDot.backgroundColor = [UIColor colorWithRed:0.10 green:0.90 blue:0.38 alpha:1.0];
            self.statusLabel.text = @"运行中";
            self.statusLabel.textColor = [UIColor colorWithRed:0.10 green:0.90 blue:0.38 alpha:1.0];

            // 状态点呼吸动画
            [self.statusDot.layer removeAllAnimations];
            CABasicAnimation *pulse = [CABasicAnimation animationWithKeyPath:@"opacity"];
            pulse.fromValue = @1.0; pulse.toValue = @0.35;
            pulse.duration = 1.1; pulse.autoreverses = YES;
            pulse.repeatCount = HUGE_VALF;
            [self.statusDot.layer addAnimation:pulse forKey:@"pulse"];
        } else {
            // 灰色待机态
            self.buttonGradient.colors = @[
                (id)[UIColor colorWithWhite:0.26 alpha:1.0].CGColor,
                (id)[UIColor colorWithWhite:0.13 alpha:1.0].CGColor,
            ];
            [self.startButton setTitle:@"启动" forState:UIControlStateNormal];
            [self.startButton setTitleColor:[UIColor colorWithWhite:0.48 alpha:1.0] forState:UIControlStateNormal];
            self.buttonShell.layer.borderColor = [UIColor colorWithWhite:0.18 alpha:1.0].CGColor;
            self.glowLayer.shadowOpacity = 0;
            self.statusDot.backgroundColor = [UIColor colorWithWhite:0.28 alpha:1.0];
            self.statusLabel.text = @"未启动";
            self.statusLabel.textColor = [UIColor colorWithWhite:0.38 alpha:1.0];

            [self.statusDot.layer removeAllAnimations];
        }

        // 状态标签布局（dot右侧）
        [self.statusLabel sizeToFit];
        CGFloat dotCX = self.view.bounds.size.width / 2 - self.statusLabel.bounds.size.width / 2 - 8;
        self.statusDot.center = CGPointMake(dotCX, self.view.bounds.size.height / 2 + 115);
        self.statusLabel.center = CGPointMake(dotCX + 6 + self.statusLabel.bounds.size.width / 2,
                                              self.view.bounds.size.height / 2 + 115);
    };

    if (animated) {
        [UIView animateWithDuration:0.35 animations:update];
    } else {
        update();
    }
}

- (void)showLogWindow {
    [[LogWindow shared] show];
}

@end
