#import <UIKit/UIKit.h>

@interface UIWindow (Private)
+ (BOOL)_isSystemWindow;
- (BOOL)_isWindowServerHostingManaged;
- (BOOL)_isSecure;
- (BOOL)_shouldCreateContextAsSecure;
- (unsigned int)_contextId;
@end
