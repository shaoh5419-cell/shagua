#import "GameStateManager.h"
#import "OCRManager.h"
#import "AIManager.h"
#import <ReplayKit/ReplayKit.h>

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
@end

@implementation GameStateManager

- (void)startMonitoring {
    self.currentPhase = GamePhaseLandlord;
    self.monitorTimer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(captureAndAnalyze) userInfo:nil repeats:YES];
}

- (void)stopMonitoring {
    [self.monitorTimer invalidate];
    self.monitorTimer = nil;
}

- (void)captureAndAnalyze {
    [self captureScreen:^(UIImage *screenshot) {
        if (!screenshot) return;

        [[OCRManager shared] recognizeImage:screenshot completion:^(NSString *text) {
            [self processOCRResult:text];
        }];
    }];
}

- (void)captureScreen:(void(^)(UIImage *image))completion {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
        UIGraphicsBeginImageContextWithOptions(keyWindow.bounds.size, NO, [UIScreen mainScreen].scale);
        [keyWindow drawViewHierarchyInRect:keyWindow.bounds afterScreenUpdates:YES];
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        if (completion) completion(image);
    });
}

- (void)processOCRResult:(NSString *)text {
    if ([text containsString:@"叫地主"] || [text containsString:@"抢地主"]) {
        self.currentPhase = GamePhaseLandlord;
        [self handleLandlordPhase:text];
    } else if ([text containsString:@"加倍"]) {
        self.currentPhase = GamePhaseDouble;
        [self handleDoublePhase:text];
    } else {
        self.currentPhase = GamePhasePlay;
        [self handlePlayPhase:text];
    }
}

- (void)handleLandlordPhase:(NSString *)text {
    self.playerHandCards = [self extractCards:text];
    if (self.playerHandCards.length != 17) return;

    NSDictionary *params = @{@"player_hand_cards": self.playerHandCards};
    [[AIManager shared] callLandlordAPI:params completion:^(NSDictionary *result) {
        if ([result[@"status"] intValue] == 0) {
            NSDictionary *data = result[@"data"];
            BOOL beLandlord = [data[@"be_landlord"] boolValue];
            BOOL competing = [data[@"competing_be_landlord"] boolValue];
            NSString *msg = beLandlord ? @"建议：叫地主" : (competing ? @"建议：抢地主" : @"建议：不叫");
            if (self.onResultUpdate) self.onResultUpdate(msg);
        }
    }];
}

- (void)handleDoublePhase:(NSString *)text {
    self.threeLandlordCards = [self extractLandlordCards:text];
    NSDictionary *params = @{@"player_hand_cards": self.playerHandCards, @"three_landlord_cards": self.threeLandlordCards};
    [[AIManager shared] callDoubleAPI:params completion:^(NSDictionary *result) {
        if ([result[@"status"] intValue] == 0) {
            NSDictionary *data = result[@"data"];
            BOOL canDouble = [data[@"can_double"] boolValue];
            NSString *msg = canDouble ? @"建议：加倍" : @"建议：不加倍";
            if (self.onResultUpdate) self.onResultUpdate(msg);
        }
    }];
}

- (void)handlePlayPhase:(NSString *)text {
    NSDictionary *params = @{
        @"player_position": @(self.playerPosition),
        @"player_hand_cards": self.playerHandCards,
        @"num_cards_left_landlord": @(20),
        @"num_cards_left_landlord_down": @(17),
        @"num_cards_left_landlord_up": @(17),
        @"three_landlord_cards": self.threeLandlordCards ?: @"",
        @"card_play_action_seq": @"",
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
            NSString *msg = [NSString stringWithFormat:@"建议出牌：%@", action.length > 0 ? action : @"不出"];
            if (self.onResultUpdate) self.onResultUpdate(msg);
        }
    }];
}

- (NSString *)extractCards:(NSString *)text {
    NSString *cards = @"";
    NSArray *cardChars = @[@"3",@"4",@"5",@"6",@"7",@"8",@"9",@"T",@"J",@"Q",@"K",@"A",@"2",@"X",@"D"];
    for (NSInteger i = 0; i < text.length; i++) {
        NSString *ch = [text substringWithRange:NSMakeRange(i, 1)];
        if ([cardChars containsObject:ch]) {
            cards = [cards stringByAppendingString:ch];
        }
    }
    return cards;
}

- (NSString *)extractLandlordCards:(NSString *)text {
    return [self extractCards:text];
}

@end



