#import "ReplayKitManager.h"
#import "LogWindow.h"

// 私有API声明 - 用于截取整个屏幕
@interface UIScreen (Private)
- (CGImageRef)_createSnapshotWithRect:(CGRect)rect;
@end

@interface ReplayKitManager ()
@property (nonatomic, strong) RPScreenRecorder *recorder;
@end

@implementation ReplayKitManager

+ (instancetype)shared {
    static ReplayKitManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        self.recorder = [RPScreenRecorder sharedRecorder];
        [[LogWindow shared] addLog:@"ReplayKitManager 已初始化"];
    }
    return self;
}

- (void)startRecording {
    if (@available(iOS 11.0, *)) {
        if (self.recorder.isRecording) {
            [[LogWindow shared] addLog:@"ReplayKit 已在录屏"];
            return;
        }

        [[LogWindow shared] addLog:@"ReplayKit 启动录屏"];
        [self.recorder startRecordingWithHandler:^(NSError * _Nullable error) {
            if (error) {
                [[LogWindow shared] addLog:[NSString stringWithFormat:@"ReplayKit 启动失败: %@", error]];
            } else {
                [[LogWindow shared] addLog:@"ReplayKit 启动成功"];
            }
        }];
    }
}

- (void)stopRecording {
    if (@available(iOS 11.0, *)) {
        if (!self.recorder.isRecording) {
            [[LogWindow shared] addLog:@"ReplayKit 未在录屏"];
            return;
        }

        [[LogWindow shared] addLog:@"ReplayKit 停止录屏"];
        [self.recorder stopRecordingWithHandler:^(RPPreviewViewController * _Nullable previewViewController, NSError * _Nullable error) {
            if (error) {
                [[LogWindow shared] addLog:[NSString stringWithFormat:@"ReplayKit 停止失败: %@", error]];
            } else {
                [[LogWindow shared] addLog:@"ReplayKit 停止成功"];
            }
        }];
    }
}

- (void)captureScreenshot:(void(^)(UIImage *image))completion {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIScreen *screen = [UIScreen mainScreen];
        CGRect screenRect = screen.bounds;

        [[LogWindow shared] addLog:[NSString stringWithFormat:@"开始截屏，屏幕尺寸:%.0fx%.0f", screenRect.size.width, screenRect.size.height]];

        // 方法1：使用私有API截取整个屏幕
        if ([screen respondsToSelector:@selector(_createSnapshotWithRect:)]) {
            @try {
                CGImageRef cgImage = [screen _createSnapshotWithRect:screenRect];
                if (cgImage) {
                    UIImage *screenshot = [UIImage imageWithCGImage:cgImage];
                    CGImageRelease(cgImage);
                    [[LogWindow shared] addLog:@"私有API截屏成功"];
                    if (completion) completion(screenshot);
                    return;
                }
            } @catch (NSException *exception) {
                [[LogWindow shared] addLog:[NSString stringWithFormat:@"私有API异常: %@", exception]];
            }
        }

        [[LogWindow shared] addLog:@"私有API不可用，尝试降级方案"];

        // 方法2：使用 UIGraphics 截屏
        UIGraphicsBeginImageContextWithOptions(screenRect.size, NO, screen.scale);
        CGContextRef context = UIGraphicsGetCurrentContext();
        if (!context) {
            [[LogWindow shared] addLog:@"创建图形上下文失败"];
            UIGraphicsEndImageContext();
            if (completion) completion(nil);
            return;
        }

        for (UIWindow *window in [UIApplication sharedApplication].windows) {
            if (window.windowLevel < 10000000) {
                [window.layer renderInContext:context];
            }
        }
        UIImage *screenshot = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();

        if (screenshot) {
            [[LogWindow shared] addLog:@"UIGraphics 截屏成功"];
            if (completion) completion(screenshot);
        } else {
            [[LogWindow shared] addLog:@"UIGraphics 截屏失败"];
            if (completion) completion(nil);
        }
    });
}

@end
