#import "GameStateManager.h"
#import "OCRManager.h"
#import "AIManager.h"
#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>

// 私有API声明
@interface UIScreen (Private)
- (CGImageRef)_createSnapshotWithRect:(CGRect)rect;
@end

typedef NS_ENUM(NSInteger, GamePhase) {
    GamePhaseIdle,
    GamePhaseLandlord,
    GamePhaseDouble,
    GamePhasePlay
};

@interface GameStateManager ()
@property (nonatomic, assign) GamePhase currentPhase;
@property (nonatomic, strong) NSTimer *monitorTimer;
@property (nonatomic, strong) NSString *playerHandCards;
@property (nonatomic, strong) NSString *threeLandlordCards;
@property (nonatomic, assign) NSInteger playerPosition;
@property (nonatomic, strong) NSMutableString *cardPlaySeq;
@property (nonatomic, assign) NSInteger landlordCards;
@property (nonatomic, assign) NSInteger landlordDownCards;
@property (nonatomic, assign) NSInteger landlordUpCards;
@end

@implementation GameStateManager

- (instancetype)init {
    if (self = [super init]) {
        self.cardPlaySeq = [NSMutableString string];
        self.landlordCards = 20;
        self.landlordDownCards = 17;
        self.landlordUpCards = 17;
    }
    return self;
}

- (void)startMonitoring {
    self.currentPhase = GamePhaseLandlord;
    if (self.onResultUpdate) self.onResultUpdate(@"开始监控...");
    self.monitorTimer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(captureAndAnalyze) userInfo:nil repeats:YES];
    [self captureAndAnalyze];  // 立即执行一次
}

- (void)stopMonitoring {
    [self.monitorTimer invalidate];
    self.monitorTimer = nil;
}

- (void)captureAndAnalyze {
    if (self.onResultUpdate) self.onResultUpdate(@"正在截屏...");

    [self captureScreen:^(UIImage *screenshot) {
        if (!screenshot) {
            if (self.onResultUpdate) self.onResultUpdate(@"截屏失败");
            return;
        }

        if (self.onResultUpdate) self.onResultUpdate(@"截屏成功，识别中...");

        CGFloat screenHeight = screenshot.size.height;
        CGFloat screenWidth = screenshot.size.width;

        // 识别手牌区域（底部 25%，这里通常显示手牌）
        CGRect handRect = CGRectMake(0, screenHeight * 0.75, screenWidth, screenHeight * 0.25);
        UIImage *handArea = [self cropImage:screenshot toRect:handRect];

        // 识别中央区域（用于判断游戏阶段和底牌）
        CGRect centerRect = CGRectMake(screenWidth * 0.2, screenHeight * 0.3, screenWidth * 0.6, screenHeight * 0.4);
        UIImage *centerArea = [self cropImage:screenshot toRect:centerRect];

        [[OCRManager shared] recognizeImage:centerArea completion:^(NSString *centerText) {
            [[OCRManager shared] recognizeImage:handArea completion:^(NSString *handText) {
                if (self.onResultUpdate) self.onResultUpdate(@"OCR完成，分析中...");
                [self processOCRResult:centerText handText:handText screenshot:screenshot];
            }];
        }];
    }];
}

- (UIImage *)cropImage:(UIImage *)image toRect:(CGRect)rect {
    CGImageRef imageRef = CGImageCreateWithImageInRect(image.CGImage, rect);
    UIImage *cropped = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    return cropped;
}

- (void)captureScreen:(void(^)(UIImage *image))completion {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIScreen *screen = [UIScreen mainScreen];
        CGRect screenRect = screen.bounds;

        NSLog(@"开始截屏，屏幕尺寸: %.0fx%.0f", screenRect.size.width, screenRect.size.height);

        // 使用私有API截取整个屏幕
        if ([screen respondsToSelector:@selector(_createSnapshotWithRect:)]) {
            CGImageRef cgImage = [screen _createSnapshotWithRect:screenRect];
            if (cgImage) {
                UIImage *screenshot = [UIImage imageWithCGImage:cgImage];
                CGImageRelease(cgImage);
                NSLog(@"私有API截屏成功");
                if (completion) completion(screenshot);
                return;
            }
            NSLog(@"私有API截屏失败");
        } else {
            NSLog(@"私有API不可用");
        }

        // 降级方案：截取所有窗口
        UIGraphicsBeginImageContextWithOptions(screenRect.size, NO, screen.scale);
        CGContextRef context = UIGraphicsGetCurrentContext();
        if (!context) {
            NSLog(@"创建图形上下文失败");
            UIGraphicsEndImageContext();
            if (completion) completion(nil);
            return;
        }

        for (UIWindow *window in [UIApplication sharedApplication].windows) {
            if (window.windowLevel < 10000000) {  // 排除悬浮窗
                [window.layer renderInContext:context];
            }
        }
        UIImage *screenshot = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();

        NSLog(@"降级方案截屏: %@", screenshot ? @"成功" : @"失败");
        if (completion) completion(screenshot);
    });
}

- (void)processOCRResult:(NSString *)centerText handText:(NSString *)handText screenshot:(UIImage *)screenshot {
    // 提取手牌
    NSString *extractedCards = [self extractCards:handText];

    // 输出调试信息到悬浮窗
    NSString *debugInfo = [NSString stringWithFormat:@"中央:%@ | 手牌:%@ | 提取:%@",
                          centerText.length > 0 ? centerText : @"无",
                          handText.length > 0 ? handText : @"无",
                          extractedCards.length > 0 ? extractedCards : @"无"];

    if (self.onResultUpdate) self.onResultUpdate(debugInfo);

    // 判断游戏阶段
    if ([centerText containsString:@"叫地主"] || [centerText containsString:@"抢地主"]) {
        self.currentPhase = GamePhaseLandlord;
        [self handleLandlordPhase:extractedCards];
    } else if ([centerText containsString:@"加倍"]) {
        self.currentPhase = GamePhaseDouble;
        [self handleDoublePhase:centerText screenshot:screenshot];
    } else if (extractedCards.length > 0) {
        self.currentPhase = GamePhasePlay;
        [self handlePlayPhase:extractedCards];
    }
}

- (void)handleLandlordPhase:(NSString *)cards {
    if (cards.length < 13 || cards.length > 17) {
        if (self.onResultUpdate) self.onResultUpdate([NSString stringWithFormat:@"手牌数量异常: %ld张", (long)cards.length]);
        return;
    }

    self.playerHandCards = cards;
    NSDictionary *params = @{@"player_hand_cards": cards};
    [[AIManager shared] callLandlordAPI:params completion:^(NSDictionary *result) {
        if ([result[@"status"] intValue] == 0) {
            NSDictionary *data = result[@"data"];
            BOOL beLandlord = [data[@"be_landlord"] boolValue];
            BOOL competing = [data[@"competing_be_landlord"] boolValue];
            NSString *msg = beLandlord ? @"叫地主" : (competing ? @"抢地主" : @"不叫");
            if (self.onResultUpdate) self.onResultUpdate(msg);
        } else {
            if (self.onResultUpdate) self.onResultUpdate(@"AI分析失败");
        }
    }];
}

- (void)handleDoublePhase:(NSString *)text screenshot:(UIImage *)screenshot {
    // 识别屏幕中央的三张底牌
    UIImage *landlordArea = [self cropImage:screenshot toRect:CGRectMake(screenshot.size.width * 0.3, screenshot.size.height * 0.4, screenshot.size.width * 0.4, screenshot.size.height * 0.2)];

    [[OCRManager shared] recognizeImage:landlordArea completion:^(NSString *landlordText) {
        self.threeLandlordCards = [self extractCards:landlordText];
        NSDictionary *params = @{@"player_hand_cards": self.playerHandCards ?: @"", @"three_landlord_cards": self.threeLandlordCards ?: @""};
        [[AIManager shared] callDoubleAPI:params completion:^(NSDictionary *result) {
            if ([result[@"status"] intValue] == 0) {
                NSDictionary *data = result[@"data"];
                BOOL canDouble = [data[@"can_double"] boolValue];
                NSString *msg = canDouble ? @"建议：加倍" : @"建议：不加倍";
                if (self.onResultUpdate) self.onResultUpdate(msg);
            }
        }];
    }];
}

- (void)handlePlayPhase:(NSString *)cards {
    // 更新手牌
    if (cards.length > 0 && cards.length <= 20) {
        self.playerHandCards = cards;
    }

    // 如果没有手牌数据，跳过
    if (!self.playerHandCards || self.playerHandCards.length == 0) {
        if (self.onResultUpdate) self.onResultUpdate(@"等待识别手牌...");
        return;
    }

    NSDictionary *params = @{
        @"player_position": @(self.playerPosition),
        @"player_hand_cards": self.playerHandCards,
        @"num_cards_left_landlord": @(self.landlordCards),
        @"num_cards_left_landlord_down": @(self.landlordDownCards),
        @"num_cards_left_landlord_up": @(self.landlordUpCards),
        @"three_landlord_cards": self.threeLandlordCards ?: @"",
        @"card_play_action_seq": self.cardPlaySeq,
        @"other_hand_cards": @"",
        @"last_move_landlord": @"",
        @"last_move_landlord_down": @"",
        @"last_move_landlord_up": @"",
        @"played_cards_landlord": @"",
        @"played_cards_landlord_down": @"",
        @"played_cards_landlord_up": @"",
        @"bomb_num": @(0)
    };

    [[AIManager shared] callBestActionAPI:params completion:^(NSDictionary *result) {
        if ([result[@"status"] intValue] == 0) {
            NSString *action = result[@"data"][@"best_action"];
            NSString *msg = action.length > 0 ? action : @"不出";
            if (self.onResultUpdate) self.onResultUpdate(msg);
        } else {
            if (self.onResultUpdate) self.onResultUpdate(@"AI分析中...");
        }
    }];
}

- (NSString *)extractCards:(NSString *)text {
    // 预处理：统一格式
    text = [text stringByReplacingOccurrencesOfString:@" " withString:@""];
    text = [text stringByReplacingOccurrencesOfString:@"♠" withString:@""];
    text = [text stringByReplacingOccurrencesOfString:@"♥" withString:@""];
    text = [text stringByReplacingOccurrencesOfString:@"♣" withString:@""];
    text = [text stringByReplacingOccurrencesOfString:@"♦" withString:@""];
    text = [text stringByReplacingOccurrencesOfString:@"10" withString:@"T"];
    text = [text stringByReplacingOccurrencesOfString:@"小王" withString:@"X"];
    text = [text stringByReplacingOccurrencesOfString:@"大王" withString:@"D"];
    text = [text stringByReplacingOccurrencesOfString:@"王" withString:@""];

    NSMutableString *cards = [NSMutableString string];
    NSArray *validCards = @[@"3",@"4",@"5",@"6",@"7",@"8",@"9",@"T",@"J",@"Q",@"K",@"A",@"2",@"X",@"D"];

    for (NSInteger i = 0; i < text.length; i++) {
        NSString *ch = [text substringWithRange:NSMakeRange(i, 1)];
        if ([validCards containsObject:ch]) {
            [cards appendString:ch];
        }
    }
    return cards;
}

- (NSString *)extractLandlordCards:(NSString *)text {
    return [self extractCards:text];
}

- (void)updateCardCounts:(NSString *)playedCards byPlayer:(NSInteger)position {
    NSInteger count = playedCards.length;
    if (position == 0) {
        self.landlordCards -= count;
    } else if (position == 1) {
        self.landlordDownCards -= count;
    } else if (position == 2) {
        self.landlordUpCards -= count;
    }
}

- (void)resetGame {
    self.currentPhase = GamePhaseIdle;
    self.playerHandCards = nil;
    self.threeLandlordCards = nil;
    self.playerPosition = 0;
    [self.cardPlaySeq setString:@""];
    self.landlordCards = 20;
    self.landlordDownCards = 17;
    self.landlordUpCards = 17;
}

@end



