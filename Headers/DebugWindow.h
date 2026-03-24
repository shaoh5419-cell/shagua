#import <UIKit/UIKit.h>

@interface DebugWindow : UIWindow
+ (instancetype)shared;
- (void)log:(NSString *)message;
- (void)show;
- (void)hide;
- (void)clear;
@end
