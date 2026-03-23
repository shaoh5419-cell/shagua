#import "OCRManager.h"

#define BAIDU_API_KEY @"Iy25AXdfIHiEVFZwRt6N3cFL"
#define BAIDU_SECRET_KEY @"PZNg7SRbQlILiZA7Ln83QWAVeApqlYU2"

@interface OCRManager ()
@property (nonatomic, strong) NSString *accessToken;
@end

@implementation OCRManager

+ (instancetype)shared {
    static OCRManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[OCRManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        [self getAccessToken];
    }
    return self;
}

- (void)getAccessToken {
    NSString *urlString = [NSString stringWithFormat:@"https://aip.baidubce.com/oauth/2.0/token?grant_type=client_credentials&client_id=%@&client_secret=%@", BAIDU_API_KEY, BAIDU_SECRET_KEY];

    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (!error && data) {
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            self.accessToken = json[@"access_token"];
        }
    }] resume];
}

- (void)recognizeImage:(UIImage *)image completion:(void(^)(NSString *result))completion {
    if (!self.accessToken) {
        if (completion) completion(@"");
        return;
    }

    NSData *imageData = UIImageJPEGRepresentation(image, 0.8);
    NSString *base64Image = [imageData base64EncodedStringWithOptions:0];

    NSString *urlString = [NSString stringWithFormat:@"https://aip.baidubce.com/rest/2.0/ocr/v1/general_basic?access_token=%@", self.accessToken];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    request.HTTPMethod = @"POST";
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];

    NSString *bodyString = [NSString stringWithFormat:@"image=%@", [base64Image stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
    request.HTTPBody = [bodyString dataUsingEncoding:NSUTF8StringEncoding];

    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (!error && data) {
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            NSArray *results = json[@"words_result"];
            NSMutableString *text = [NSMutableString string];
            for (NSDictionary *item in results) {
                [text appendString:item[@"words"]];
            }
            if (completion) completion(text);
        } else {
            if (completion) completion(@"");
        }
    }] resume];
}

@end
