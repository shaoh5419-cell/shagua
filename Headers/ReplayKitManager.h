#import <Foundation/Foundation.h>
#import <ReplayKit/ReplayKit.h>

@interface ReplayKitManager : NSObject

+ (instancetype)shared;

- (void)startRecording;
- (void)stopRecording;
- (void)captureScreenshot:(void(^)(UIImage *image))completion;

@end
