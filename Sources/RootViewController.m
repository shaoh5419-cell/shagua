#import "RootViewController.h"
#import <spawn.h>
#import <sys/wait.h>
#import <mach-o/dyld.h>
#import <notify.h>
#import "PersonaHelpers.h"

extern char **environ;

#define DDZ_HUD_EXIT_NOTIFICATION "com.ddz.helper.hud.exit"

@interface RootViewController ()
@property (nonatomic, strong) UIButton *startButton;
@property (nonatomic, assign) BOOL isRunning;
@end

@implementation RootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithRed:0.05 green:0.05 blue:0.1 alpha:1.0];

    self.startButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.startButton.frame = CGRectMake(0, 0, 180, 180);
    self.startButton.center = self.view.center;
    self.startButton.layer.cornerRadius = 90;

    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = self.startButton.bounds;
    gradient.colors = @[(id)[UIColor colorWithRed:0.2 green:0.5 blue:1.0 alpha:1.0].CGColor,
                        (id)[UIColor colorWithRed:0.4 green:0.7 blue:1.0 alpha:1.0].CGColor];
    gradient.cornerRadius = 90;
    [self.startButton.layer insertSublayer:gradient atIndex:0];

    [self.startButton setTitle:@"启动" forState:UIControlStateNormal];
    [self.startButton setTitle:@"运行中" forState:UIControlStateSelected];
    self.startButton.titleLabel.font = [UIFont boldSystemFontOfSize:28];
    [self.startButton addTarget:self action:@selector(startButtonTapped) forControlEvents:UIControlEventTouchUpInside];

    self.startButton.layer.shadowColor = [UIColor colorWithRed:0.2 green:0.5 blue:1.0 alpha:1.0].CGColor;
    self.startButton.layer.shadowOffset = CGSizeMake(0, 8);
    self.startButton.layer.shadowRadius = 20;
    self.startButton.layer.shadowOpacity = 0.5;

    [self.view addSubview:self.startButton];
}

- (void)startButtonTapped {
    if (!self.isRunning) {
        NSString *plistPath = @"/Library/LaunchDaemons/com.ddz.helper.daemon.plist";

        if ([[NSFileManager defaultManager] fileExistsAtPath:plistPath]) {
            // LaunchDaemon plist已存在，通过launchctl加载
            static const char *launchctlPath = "/usr/bin/launchctl";
            const char *args[] = {launchctlPath, "load", [plistPath UTF8String], NULL};

            posix_spawnattr_t attr;
            posix_spawnattr_init(&attr);
            posix_spawnattr_set_persona_np(&attr, 99, POSIX_SPAWN_PERSONA_FLAGS_OVERRIDE);
            posix_spawnattr_set_persona_uid_np(&attr, 0);
            posix_spawnattr_set_persona_gid_np(&attr, 0);

            pid_t pid;
            int rc = posix_spawn(&pid, launchctlPath, NULL, &attr, (char **)args, environ);
            posix_spawnattr_destroy(&attr);

            if (rc == 0) {
                int status;
                waitpid(pid, &status, 0);
                self.startButton.selected = YES;
                self.isRunning = YES;
                [self showAlert:@"成功" message:@"悬浮窗已启动，请切换到其他应用查看"];
            } else {
                [self showAlert:@"错误" message:[NSString stringWithFormat:@"启动失败: %d (%s)", rc, strerror(rc)]];
            }
        } else {
            // 参考TrollSpeed: 直接以root身份启动自身（带-hud参数）
            uint32_t size = 0;
            _NSGetExecutablePath(NULL, &size);
            char *executablePath = (char *)malloc(size);
            _NSGetExecutablePath(executablePath, &size);

            posix_spawnattr_t attr;
            posix_spawnattr_init(&attr);
            posix_spawnattr_set_persona_np(&attr, 99, POSIX_SPAWN_PERSONA_FLAGS_OVERRIDE);
            posix_spawnattr_set_persona_uid_np(&attr, 0);
            posix_spawnattr_set_persona_gid_np(&attr, 0);
            posix_spawnattr_setpgroup(&attr, 0);
            posix_spawnattr_setflags(&attr, POSIX_SPAWN_SETPGROUP);

            pid_t task_pid;
            const char *args[] = {executablePath, "-hud", NULL};
            int rc = posix_spawn(&task_pid, executablePath, NULL, &attr, (char **)args, environ);
            posix_spawnattr_destroy(&attr);
            free(executablePath);

            if (rc == 0) {
                int unused;
                waitpid(task_pid, &unused, WNOHANG);
                self.startButton.selected = YES;
                self.isRunning = YES;
                [self showAlert:@"成功" message:@"悬浮窗已启动，请切换到其他应用查看"];
            } else {
                [self showAlert:@"错误" message:[NSString stringWithFormat:@"启动失败: %d (%s)", rc, strerror(rc)]];
            }
        }
    } else {
        NSString *plistPath = @"/Library/LaunchDaemons/com.ddz.helper.daemon.plist";
        if ([[NSFileManager defaultManager] fileExistsAtPath:plistPath]) {
            static const char *launchctlPath = "/usr/bin/launchctl";
            const char *args[] = {launchctlPath, "unload", [plistPath UTF8String], NULL};

            posix_spawnattr_t attr;
            posix_spawnattr_init(&attr);
            posix_spawnattr_set_persona_np(&attr, 99, POSIX_SPAWN_PERSONA_FLAGS_OVERRIDE);
            posix_spawnattr_set_persona_uid_np(&attr, 0);
            posix_spawnattr_set_persona_gid_np(&attr, 0);

            pid_t pid;
            posix_spawn(&pid, launchctlPath, NULL, &attr, (char **)args, environ);
            posix_spawnattr_destroy(&attr);
            int unused;
            waitpid(pid, &unused, 0);
        } else {
            // 通知HUD进程退出
            notify_post(DDZ_HUD_EXIT_NOTIFICATION);
        }
        self.startButton.selected = NO;
        self.isRunning = NO;
    }
}

- (void)showAlert:(NSString *)title message:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
        message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
