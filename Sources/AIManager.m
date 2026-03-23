#import "AIManager.h"

#define AI_API_KEY @"sk-efbbb901434dc92adc3f5a7cf6d58a8789c5e13467e6cfa2e7363008f90f1f93"
#define AI_BASE_URL @"http://114.66.34.179:8888"

@implementation AIManager

+ (instancetype)shared {
    static AIManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[AIManager alloc] init];
    });
    return instance;
}

- (void)sendRequest:(NSString *)endpoint params:(NSDictionary *)params completion:(void(^)(NSDictionary *result))completion {
    NSString *urlString = [NSString stringWithFormat:@"%@%@", AI_BASE_URL, endpoint];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    request.HTTPMethod = @"POST";
    [request setValue:AI_API_KEY forHTTPHeaderField:@"X-API-KEY"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];

    NSMutableArray *bodyParts = [NSMutableArray array];
    for (NSString *key in params) {
        id value = params[key];
        NSString *encodedValue = [[NSString stringWithFormat:@"%@", value] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        [bodyParts addObject:[NSString stringWithFormat:@"%@=%@", key, encodedValue]];
    }
    request.HTTPBody = [[bodyParts componentsJoinedByString:@"&"] dataUsingEncoding:NSUTF8StringEncoding];

    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (!error && data) {
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            if (completion) completion(json);
        } else {
            if (completion) completion(nil);
        }
    }] resume];
}

- (void)callLandlordAPI:(NSDictionary *)params completion:(void(^)(NSDictionary *result))completion {
    [self sendRequest:@"/api/ai/can_be_landlord" params:params completion:completion];
}

- (void)callDoubleAPI:(NSDictionary *)params completion:(void(^)(NSDictionary *result))completion {
    [self sendRequest:@"/api/ai/can_double" params:params completion:completion];
}

- (void)callBestActionAPI:(NSDictionary *)params completion:(void(^)(NSDictionary *result))completion {
    [self sendRequest:@"/api/ai/best_action" params:params completion:completion];
}

@end
