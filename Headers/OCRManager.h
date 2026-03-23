#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface OCRManager : NSObject
+ (instancetype)shared;
- (void)recognizeImage:(UIImage *)image completion:(void(^)(NSString *result))completion;
@end
