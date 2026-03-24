#import <Foundation/Foundation.h>

__attribute__((weak_import))
void GSInitialize(void);

__attribute__((weak_import))
void GSEventInitialize(int);

__attribute__((weak_import))
void GSEventPushRunLoopMode(CFStringRef mode);
