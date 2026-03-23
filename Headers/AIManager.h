#import <Foundation/Foundation.h>

@interface AIManager : NSObject
+ (instancetype)shared;
- (void)callLandlordAPI:(NSDictionary *)params completion:(void(^)(NSDictionary *result))completion;
- (void)callDoubleAPI:(NSDictionary *)params completion:(void(^)(NSDictionary *result))completion;
- (void)callBestActionAPI:(NSDictionary *)params completion:(void(^)(NSDictionary *result))completion;
@end
