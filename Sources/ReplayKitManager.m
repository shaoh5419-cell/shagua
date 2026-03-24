#import "ReplayKitManager.h"

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

        // ReplayKit 2: 支持录制整个屏幕（包括其他应用）
        [self.recorder startRecordingWithHandler:^(NSError * _Nullable error) {
            if (error) {
                NSLog(@"ReplayKit 2 录屏启动失败: %@", error);
            } else {
                NSLog(@"ReplayKit 2 录屏已启动");
            }
        }];
    }
}

- (void)stopRecording {
    if (@available(iOS 11.0, *)) {
        if (!self.recorder.isRecording) return;

        [self.recorder stopRecordingWithHandler:^(RPPreviewViewController * _Nullable previewViewController, NSError * _Nullable error) {
            if (error) {
                NSLog(@"ReplayKit 2 录屏停止失败: %@", error);
            } else {
                NSLog(@"ReplayKit 2 录屏已停止");
            }
        }];
    }
}

- (void)captureScreenshot:(void(^)(UIImage *image))completion {
    if (@available(iOS 11.0, *)) {
        // ReplayKit 2: captureScreenshot 可以截取整个屏幕
        [self.recorder captureScreenshotWithCompletion:^(UIImage * _Nullable screenshot, NSError * _Nullable error) {
            if (error) {
                NSLog(@"ReplayKit 2 截屏失败: %@", error);
                if (completion) completion(nil);
            } else {
                if (completion) completion(screenshot);
            }
        }];
    }
}

@end
