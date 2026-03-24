#import "RootViewController.h"
#import <spawn.h>
#import <sys/wait.h>
#import "PersonaHelpers.h"

extern char **environ;

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

- (int)spawnAsRoot:(const char *)path args:(const char **)args {
    posix_spawnattr_t attr;
    posix_spawnattr_init(&attr);
    posix_spawnattr_set_persona_np(&attr, 99, POSIX_SPAWN_PERSONA_FLAGS_OVERRIDE);
    posix_spawnattr_set_persona_uid_np(&attr, 0);
    posix_spawnattr_set_persona_gid_np(&attr, 0);

    pid_t pid;
    int rc = posix_spawn(&pid, path, NULL, &attr, (char **)args, environ);
    posix_spawnattr_destroy(&attr);

    if (rc == 0) {
        int status;
        waitpid(pid, &status, 0);
    }
    return rc;
}

- (void)startButtonTapped {
    if (!self.isRunning) {
        NSString *plistDest = @"/Library/LaunchDaemons/com.ddz.helper.daemon.plist";
        NSString *plistSrc = [[NSBundle mainBundle] pathForResource:@"com.ddz.helper.daemon" ofType:@"plist"];

        // 如果plist不存在，用root权限复制进去
        if (![[NSFileManager defaultManager] fileExistsAtPath:plistDest]) {
            const char *cpArgs[] = {"/bin/cp", [plistSrc UTF8String], [plistDest UTF8String], NULL};
            int rc = [self spawnAsRoot:"/bin/cp" args:cpArgs];
            if (rc != 0) {
                [self showAlert:@"错误" message:[NSString stringWithFormat:@"无法安装配置文件: %d (%s)", rc, strerror(rc)]];
                return;
            }
            // 设置权限
            const char *chmodArgs[] = {"/bin/chmod", "0644", [plistDest UTF8String], NULL};
            [self spawnAsRoot:"/bin/chmod" args:chmodArgs];
        }

        // 启动daemon
        const char *loadArgs[] = {"/usr/bin/launchctl", "load", [plistDest UTF8String], NULL};
        int rc = [self spawnAsRoot:"/usr/bin/launchctl" args:loadArgs];

        if (rc == 0) {
            self.startButton.selected = YES;
            self.isRunning = YES;
            [self showAlert:@"成功" message:@"悬浮窗已启动，请切换到其他应用查看"];
        } else {
            [self showAlert:@"错误" message:[NSString stringWithFormat:@"启动失败: %d (%s)", rc, strerror(rc)]];
        }
    } else {
        const char *unloadArgs[] = {"/usr/bin/launchctl", "unload", "/Library/LaunchDaemons/com.ddz.helper.daemon.plist", NULL};
        [self spawnAsRoot:"/usr/bin/launchctl" args:unloadArgs];
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
