#import <Foundation/Foundation.h>

@interface SBSAccessibilityWindowHostingController : NSObject
- (void)registerWindowWithContextID:(unsigned int)contextId atLevel:(double)level;
@end
