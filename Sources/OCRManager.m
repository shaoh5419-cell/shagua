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

    if (!image.CGImage) {
        NSLog(@"OCR: 图像无效");
        if (completion) completion(@"");
        return;
    }

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @try {
            NSLog(@"OCR: 开始识别，图像尺寸:%.0fx%.0f", image.size.width, image.size.height);

            VNRecognizeTextRequest *request = [[VNRecognizeTextRequest alloc] initWithCompletionHandler:^(VNRequest *request, NSError *error) {
                if (error) {
                    NSLog(@"OCR错误: %@", error);
                    if (completion) completion(@"");
                    return;
                }

                NSMutableString *text = [NSMutableString string];
                NSInteger resultCount = 0;

                if (request.results && request.results.count > 0) {
                    resultCount = request.results.count;
                    for (VNRecognizedTextObservation *observation in request.results) {
                        VNRecognizedText *topCandidate = [observation topCandidates:1].firstObject;
                        if (topCandidate) {
                            [text appendString:topCandidate.string];
                            [text appendString:@" "];
                        }
                    }
                }

                NSLog(@"OCR: 识别完成，结果数:%ld，文本:%@", (long)resultCount, text.length > 0 ? text : @"空");

                dispatch_async(dispatch_get_main_queue(), ^{
                    if (completion) completion(text.length > 0 ? text : @"");
                });
            }];

            // 使用快速识别模式
            request.recognitionLevel = VNRequestTextRecognitionLevelFast;
            request.recognitionLanguages = @[@"zh-Hans"];
            request.usesLanguageCorrection = NO;

            VNImageRequestHandler *handler = [[VNImageRequestHandler alloc] initWithCGImage:image.CGImage options:@{}];
            NSError *error = nil;
            BOOL success = [handler performRequests:@[request] error:&error];

            NSLog(@"OCR: performRequests 返回:%d，错误:%@", success, error);

            if (!success || error) {
                NSLog(@"OCR执行错误: %@", error);
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (completion) completion(@"");
                });
            }
        } @catch (NSException *exception) {
            NSLog(@"OCR异常: %@", exception);
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) completion(@"");
            });
        }
    });
}

@end
