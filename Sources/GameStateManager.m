#import "GameStateManager.h"
#import "OCRManager.h"
#import "AIManager.h"
#import "ReplayKitManager.h"
#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>

// 私有API声明 - 用于截取整个屏幕（包括其他应用）
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
@property (nonatomic, strong) NSString *lastRecognizedText;
@property (nonatomic, assign) NSTimeInterval lastRecognitionTime;
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
    if (self.onResultUpdate) self.onResultUpdate(@"监控中...");
    [[ReplayKitManager shared] startRecording];
    self.monitorTimer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(captureAndAnalyze) userInfo:nil repeats:YES];
    [self captureAndAnalyze];
}

- (void)stopMonitoring {
    [[ReplayKitManager shared] stopRecording];
    [self.monitorTimer invalidate];
    self.monitorTimer = nil;
}

- (void)captureAndAnalyze {
    [self captureScreen:^(UIImage *screenshot) {
        if (!screenshot) {
            if (self.onResultUpdate) self.onResultUpdate(@"截图失败");
            return;
        }

        CGFloat screenHeight = screenshot.size.height;
        CGFloat screenWidth = screenshot.size.width;

        CGRect handRect = CGRectMake(0, screenHeight * 0.75, screenWidth, screenHeight * 0.25);
        UIImage *handArea = [self cropImage:screenshot toRect:handRect];

        CGRect centerRect = CGRectMake(screenWidth * 0.2, screenHeight * 0.3, screenWidth * 0.6, screenHeight * 0.4);
        UIImage *centerArea = [self cropImage:screenshot toRect:centerRect];

        // 并行识别中央区域和手牌区域，提高效率
        __block NSString *centerText = nil;
        __block NSString *handText = nil;
        __block NSInteger completedCount = 0;
        dispatch_queue_t queue = dispatch_queue_create("ocr.recognition", DISPATCH_QUEUE_SERIAL);

        [[OCRManager shared] recognizeImage:centerArea completion:^(NSString *result) {
            dispatch_async(queue, ^{
                centerText = result ?: @"";
                completedCount++;
                if (completedCount == 2) {
                    [self processOCRResult:centerText handText:handText screenshot:screenshot];
                }
            });
        }];

        [[OCRManager shared] recognizeImage:handArea completion:^(NSString *result) {
            dispatch_async(queue, ^{
                handText = result ?: @"";
                completedCount++;
                if (completedCount == 2) {
                    [self processOCRResult:centerText handText:handText screenshot:screenshot];
                }
            });
        }];
    }];
}

// 获取中央识别区域（按钮、提示文字）
- (CGRect)getCenterROI:(UIImage *)screenshot {
    CGFloat w = screenshot.size.width;
    CGFloat h = screenshot.size.height;
    // 中央区域：宽60%，高40%，垂直位置30%-70%
    return CGRectMake(w * 0.2, h * 0.3, w * 0.6, h * 0.4);
}

// 获取手牌识别区域
- (CGRect)getHandROI:(UIImage *)screenshot {
    CGFloat w = screenshot.size.width;
    CGFloat h = screenshot.size.height;
    // 下方区域：宽100%，高25%，从75%开始
    return CGRectMake(0, h * 0.75, w, h * 0.25);
}

- (UIImage *)cropImage:(UIImage *)image toRect:(CGRect)rect {
    CGImageRef imageRef = CGImageCreateWithImageInRect(image.CGImage, rect);
    UIImage *cropped = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    return cropped;
}

- (void)captureScreen:(void(^)(UIImage *image))completion {
    [[ReplayKitManager shared] captureScreenshot:^(UIImage *screenshot) {
        if (completion) completion(screenshot);
    }];
}

- (void)processOCRResult:(NSString *)centerText handText:(NSString *)handText screenshot:(UIImage *)screenshot {
    NSString *extractedCards = [self extractCards:handText];

    // 规范化文本用于判断
    NSString *normalizedCenter = [centerText lowercaseString];

    // 显示识别的卡牌
    if (extractedCards.length > 0) {
        if (self.onResultUpdate) self.onResultUpdate([NSString stringWithFormat:@"手牌:%@", extractedCards]);
    }

    if ([normalizedCenter containsString:@"叫地主"] || [normalizedCenter containsString:@"抢地主"]) {
        self.currentPhase = GamePhaseLandlord;
        [self handleLandlordPhase:extractedCards];
    } else if ([normalizedCenter containsString:@"加倍"] || [normalizedCenter containsString:@"不加倍"]) {
        self.currentPhase = GamePhaseDouble;
        [self handleDoublePhase:centerText screenshot:screenshot];
    } else if (extractedCards.length > 0) {
        self.currentPhase = GamePhasePlay;
        [self handlePlayPhase:extractedCards];
    } else {
        if (self.onResultUpdate) self.onResultUpdate(@"等待中...");
    }
}

- (void)handleLandlordPhase:(NSString *)cards {
    // 有效手牌范围：13-17张
    if (cards.length < 13 || cards.length > 17) {
        if (self.onResultUpdate) {
            if (cards.length == 0) {
                self.onResultUpdate(@"等待识别手牌...");
            } else {
                self.onResultUpdate([NSString stringWithFormat:@"手牌异常: %ld张", (long)cards.length]);
            }
        }
        return;
    }

    self.playerHandCards = cards;
    NSDictionary *params = @{@"player_hand_cards": cards};
    [[AIManager shared] callLandlordAPI:params completion:^(NSDictionary *result) {
        if (!result) {
            if (self.onResultUpdate) self.onResultUpdate(@"网络错误");
            return;
        }

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
    if (!text || text.length == 0) return @"";

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

    // 转换常见OCR错误
    text = [text stringByReplacingOccurrencesOfString:@"O" withString:@"0"];
    text = [text stringByReplacingOccurrencesOfString:@"l" withString:@"1"];
    text = [text stringByReplacingOccurrencesOfString:@"I" withString:@"1"];
    text = [text stringByReplacingOccurrencesOfString:@"S" withString:@"5"];
    text = [text stringByReplacingOccurrencesOfString:@"Z" withString:@"2"];
    text = [text stringByReplacingOccurrencesOfString:@"B" withString:@"8"];
    text = [text stringByReplacingOccurrencesOfString:@"G" withString:@"9"];

    NSMutableString *cards = [NSMutableString string];
    NSArray *validCards = @[@"3",@"4",@"5",@"6",@"7",@"8",@"9",@"T",@"J",@"Q",@"K",@"A",@"2",@"X",@"D"];

    for (NSInteger i = 0; i < text.length; i++) {
        NSString *ch = [text substringWithRange:NSMakeRange(i, 1)];
        if ([validCards containsObject:ch]) {
            [cards appendString:ch];
        }
    }

    // 去重：同一张牌最多4张
    NSMutableString *deduped = [NSMutableString string];
    NSMutableDictionary *cardCount = [NSMutableDictionary dictionary];
    for (NSInteger i = 0; i < cards.length; i++) {
        NSString *card = [cards substringWithRange:NSMakeRange(i, 1)];
        NSInteger count = [cardCount[card] integerValue];
        if (count < 4) {
            [deduped appendString:card];
            cardCount[card] = @(count + 1);
        }
    }

    return deduped;
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



