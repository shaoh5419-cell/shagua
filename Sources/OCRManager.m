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

    VNRecognizeTextRequest *request = [[VNRecognizeTextRequest alloc] initWithCompletionHandler:^(VNRequest *request, NSError *error) {
        if (error) {
            if (completion) completion(@"");
            return;
        }

        NSMutableString *text = [NSMutableString string];
        for (VNRecognizedTextObservation *observation in request.results) {
            VNRecognizedText *topCandidate = [observation topCandidates:1].firstObject;
            if (topCandidate) {
                [text appendString:topCandidate.string];
            }
        }
        if (completion) completion(text);
    }];

    request.recognitionLevel = VNRequestTextRecognitionLevelAccurate;
    request.recognitionLanguages = @[@"zh-Hans", @"en-US"];
    request.usesLanguageCorrection = YES;

    VNImageRequestHandler *handler = [[VNImageRequestHandler alloc] initWithCGImage:image.CGImage options:@{}];
    [handler performRequests:@[request] error:nil];
}

@end
