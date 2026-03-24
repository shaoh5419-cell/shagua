#import <UIKit/UIKit.h>

@interface UIApplication (Private)
- (void)_enqueueHIDEvent:(id)event;
- (void)_accessibilityInit;
- (void)__completeAndRunAsPlugin;
@end

void UIApplicationInitialize(void);
void UIApplicationInstantiateSingleton(Class cls);
