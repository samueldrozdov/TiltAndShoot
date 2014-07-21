//
//  Recap.m
//  TiltAndShoot
//
//  Created by Samuel Drozdov on 7/21/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "Recap.h"

@implementation Recap {
    CCLabelTTF *_finalScoreLabel;
    CCLabelTTF *_highScoreLabel;
    CCLabelTTF *_newHighScore;
    
    CCNode *_bronzeCover;
    CCNode *_silverCover;
    CCNode *_goldCover;
    //testing comment
}

- (void)onEnter {
    [super onEnter];
}
- (void)onExit {
    [super onExit];
}

- (void)didLoadFromCCB {
    _finalScoreLabel.string = [NSString stringWithFormat:@"%d", ((NSNumber*)[[NSUserDefaults standardUserDefaults] objectForKey:@"PreviousScore"]).intValue];
    _highScoreLabel.string = [NSString stringWithFormat:@"%d", ((NSNumber*)[[NSUserDefaults standardUserDefaults] objectForKey:@"HighScore"]).intValue];
    
    int prevScore = ((NSNumber*)[[NSUserDefaults standardUserDefaults] objectForKey:@"PreviousScore"]).intValue;
    if(prevScore > 50) {
        _bronzeCover.visible = false;
    }
    if(prevScore > 100) {
        _silverCover.visible = false;
    }
    if(prevScore > 150) {
        _goldCover.visible = false;
    }
}

-(void)restart {
    CCScene *recapScene = [CCBReader loadAsScene:@"MainScene"];
    [[CCDirector sharedDirector] replaceScene:recapScene];
}


@end
