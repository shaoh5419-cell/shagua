#import "OCRManager.h"
#import <AipOcrSdk/AipOcrService.h>

#define BAIDU_OCR_API_KEY @"Iy25AXdfIHiEVFZwRt6N3cFL"
#define BAIDU_OCR_SECRET_KEY @"PZNg7SRbQlILiZA7Ln83QWAVeApqlYU2"

@interface OCRManager ()
@property (nonatomic, strong) AipOcrService *ocrService;
@end

@implementation OCRManager

+ (instancetype)shared {
    static OCRManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        self.ocrService = [AipOcrService shardService];
        // 使用API Key和Secret Key授权
        [self.ocrService authWithAK:BAIDU_OCR_API_KEY andSK:BAIDU_OCR_SECRET_KEY];
        NSLog(@"OCR: 百度OCR SDK已初始化");
    }
    return self;
}

- (void)recognizeImage:(UIImage *)image completion:(void(^)(NSString *result))completion {
    if (!image) {
        if (completion) completion(@"");
        return;
    }

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"OCR: 开始SDK识别，图像尺寸:%.0fx%.0f", image.size.width, image.size.height);

        // 使用通用文字识别（不含位置信息版）
        [self.ocrService detectTextBasicFromImage:image
                                      withOptions:@{}
                                   successHandler:^(id result) {
            NSMutableString *text = [NSMutableString string];

            if ([result isKindOfClass:[NSDictionary class]]) {
                NSDictionary *resultDict = (NSDictionary *)result;
                NSArray *wordsResult = resultDict[@"words_result"];

                if (wordsResult && [wordsResult isKindOfClass:[NSArray class]]) {
                    for (NSDictionary *item in wordsResult) {
                        NSString *words = item[@"words"];
                        if (words && [words isKindOfClass:[NSString class]]) {
                            [text appendString:words];
                            [text appendString:@" "];
                        }
                    }
                }
            }

            NSLog(@"OCR: 识别完成，文本:%@", text.length > 0 ? text : @"空");

            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) completion(text.length > 0 ? text : @"");
            });
        }
                                      failHandler:^(NSError *err) {
            NSLog(@"OCR识别失败: %@", err);
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) completion(@"");
            });
        }];
    });
}

@end
