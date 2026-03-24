#import "OCRManager.h"
#import <Vision/Vision.h>

@implementation OCRManager

+ (instancetype)shared {
    static OCRManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (void)recognizeImage:(UIImage *)image completion:(void(^)(NSString *result))completion {
    if (!image) {
        if (completion) completion(@"");
        return;
    }

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // 设置超时：5秒后如果还没完成就返回空
        __block BOOL completed = NO;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (!completed) {
                completed = YES;
                if (completion) completion(@"");
            }
        });

        VNRecognizeTextRequest *request = [[VNRecognizeTextRequest alloc] initWithCompletionHandler:^(VNRequest *request, NSError *error) {
            if (completed) return;
            completed = YES;

            if (error) {
                NSLog(@"OCR错误: %@", error);
                if (completion) completion(@"");
                return;
            }

            NSMutableString *text = [NSMutableString string];
            for (VNRecognizedTextObservation *observation in request.results) {
                VNRecognizedText *topCandidate = [observation topCandidates:1].firstObject;
                if (topCandidate) {
                    [text appendString:topCandidate.string];
                    [text appendString:@" "];
                }
            }

            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) completion(text);
            });
        }];

        // 使用快速识别模式
        request.recognitionLevel = VNRequestTextRecognitionLevelFast;
        request.recognitionLanguages = @[@"zh-Hans"];
        request.usesLanguageCorrection = NO;

        VNImageRequestHandler *handler = [[VNImageRequestHandler alloc] initWithCGImage:image.CGImage options:@{}];
        NSError *error = nil;
        [handler performRequests:@[request] error:&error];

        if (error) {
            NSLog(@"OCR执行错误: %@", error);
            if (!completed) {
                completed = YES;
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (completion) completion(@"");
                });
            }
        }
    });
}

@end
