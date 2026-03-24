#import "ReplayKitManager.h"

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
    }
    return self;
}

- (void)startRecording {
    if (@available(iOS 11.0, *)) {
        if (self.recorder.isRecording) return;

        [self.recorder startRecordingWithHandler:^(NSError * _Nullable error) {
            if (error) {
                NSLog(@"ReplayKit 启动失败: %@", error);
            }
        }];
    }
}

- (void)stopRecording {
    if (@available(iOS 11.0, *)) {
        if (!self.recorder.isRecording) return;

        [self.recorder stopRecordingWithHandler:^(RPPreviewViewController * _Nullable previewViewController, NSError * _Nullable error) {
            if (error) {
                NSLog(@"ReplayKit 停止失败: %@", error);
            }
        }];
    }
}

- (void)captureScreenshot:(void(^)(UIImage *image))completion {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIScreen *screen = [UIScreen mainScreen];
        CGRect screenRect = screen.bounds;

        // 使用私有API截取整个屏幕
        if ([screen respondsToSelector:@selector(_createSnapshotWithRect:)]) {
            CGImageRef cgImage = [screen _createSnapshotWithRect:screenRect];
            if (cgImage) {
                UIImage *screenshot = [UIImage imageWithCGImage:cgImage];
                CGImageRelease(cgImage);
                if (completion) completion(screenshot);
                return;
            }
        }

        // 降级方案：使用 UIGraphics 截屏
        UIGraphicsBeginImageContextWithOptions(screenRect.size, NO, screen.scale);
        CGContextRef context = UIGraphicsGetCurrentContext();
        if (!context) {
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

        if (completion) completion(screenshot);
    });
}

@end
