#import <Foundation/Foundation.h>

__attribute__((weak_import))
void BKSDisplayServicesStart(void);

__attribute__((weak_import))
void BKSHIDEventRegisterEventCallback(void (*callback)(void*, void*, void*, void*));
