#import <UIKit/UIKit.h>

@interface LogWindow : UIWindow

+ (instancetype)shared;
- (void)addLog:(NSString *)message;
- (void)show;
- (void)hide;

@end
