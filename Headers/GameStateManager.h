#import <Foundation/Foundation.h>

typedef void(^ResultUpdateBlock)(NSString *result);

@interface GameStateManager : NSObject
@property (nonatomic, copy) ResultUpdateBlock onResultUpdate;
- (void)startMonitoring;
- (void)stopMonitoring;
@end
