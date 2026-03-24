#import <UIKit/UIKit.h>

@interface UIApplication (Private)
- (void)_enqueueHIDEvent:(id)event;
- (void)_accessibilityInit;
- (void)__completeAndRunAsPlugin;
@end

__attribute__((weak_import))
void UIApplicationInitialize(void);

__attribute__((weak_import))
void UIApplicationInstantiateSingleton(Class cls);
