//
//  MainScene.m
//  PROJECTNAME
//
//  Created by Viktor on 10/10/13.
//  Copyright (c) 2013 Apportable. All rights reserved.
//

#import "MainScene.h"

#import <Foundation/Foundation.h>
#import <CoreMotion/CoreMotion.h>

@implementation MainScene {
    CCNode *_instructions;
    CCNode *_ball;
    CCNode *_crosshair;
    CCLabelTTF *_scoreLabel;
    CCPhysicsNode *_physicsNode;
    
    CCNode *_calibrateButton;
    CCLabelTTF *_arrowLabel;
    CCLabelTTF *_clickShootLabel;
    CCLabelTTF *_keepShootingLabel;
    CCLabelTTF *_dontHitWallsLabel;
    
    CMMotionManager *_motionManager;
    CGSize bbSize;
    float ballRadius;
    int score;
    int power;
    
    CCNodeColor *_timerCover;
}

- (void)onEnter
{
    [super onEnter];
    [_motionManager startAccelerometerUpdates];
}
- (void)onExit
{
    [super onExit];
    [_motionManager stopAccelerometerUpdates];
}

// is called when CCB file has completed loading
- (void)didLoadFromCCB {
    // tell this scene to accept touches
    self.userInteractionEnabled = TRUE;
    // enable collisions
    _physicsNode.collisionDelegate = self;
    
    // find the size of the gameplay scene
    bbSize = [[UIScreen mainScreen] bounds].size;
    
    _motionManager = [[CMMotionManager alloc] init];
    _scoreLabel.visible = false;
    ballRadius = 35.5;
    score = 0;
    power = 20;
    
    // if restart is clicked the game skips the menu screen
    if(1 == [[[NSUserDefaults standardUserDefaults] objectForKey:@"Start"] integerValue]) {
        _instructions.visible = false;
        _scoreLabel.visible = true;
        _keepShootingLabel.visible = true;
    }
}

// called on every touch in this scene
-(void) touchBegan:(UITouch *)touch withEvent:(UIEvent *)event {
    int ballX = _ball.positionInPoints.x;
    int ballY = _ball.positionInPoints.y;
    int crosshairX = _crosshair.position.x;
    int crosshairY = _crosshair.position.y;
    int crosshairDistToBall = sqrtf(powf(crosshairX - ballX, 2) + powf(crosshairY - ballY, 2));
    // check if the ball contains the crosshair
    if(ballRadius >= crosshairDistToBall) {
        _instructions.visible = false;
        _scoreLabel.visible = true;
        _keepShootingLabel.visible = true;
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:1] forKey:@"Start"];
        // increase the score and update the labels
        score++;
        _scoreLabel.string = [NSString stringWithFormat:@"%d", score];
        if(score >= 5) {
            _keepShootingLabel.visible = false;
            _dontHitWallsLabel.visible = true;
        }
        if(score >= 15) {
            _dontHitWallsLabel.visible = false;
        }
        
        // hitting the ball further from the center applies some more force
        [_ball.physicsBody applyForce:ccp((ballX-crosshairX)*power,(ballY-crosshairY)*power)];
        power += 5;
        
        // add time to timerCover's positon
        if(_timerCover.position.y < 85)
            _timerCover.position = ccp(_timerCover.position.x, _timerCover.position.y + 15);
        
        // load particle effect
        CCParticleSystem *hit = (CCParticleSystem *)[CCBReader load:@"HitParticle"];
        // make the particle effect clean itself up, once it is completed
        hit.autoRemoveOnFinish = TRUE;
        // place the particle effect on the ball's position
        hit.position = _ball.positionInPoints;
        [_ball.parent addChild:hit z:-1];
    } else {
        // load particle effect
        CCParticleSystem *missed = (CCParticleSystem *)[CCBReader load:@"ShootParticle"];
        // make the particle effect clean itself up, once it is completed
        missed.autoRemoveOnFinish = TRUE;
        // place the particle effect on the crosshair's position
        missed.position = _crosshair.position;
        [self addChild:missed z:0];
    }
}

// updates that happen every 1/60th second
-(void)update:(CCTime)delta {
    CMAccelerometerData *accelerometerData = _motionManager.accelerometerData;
    CMAcceleration acceleration = accelerometerData.acceleration;
    CGFloat newXPosition = _crosshair.position.x + (acceleration.x + [[[NSUserDefaults standardUserDefaults] objectForKey:@"calibrationX"] floatValue]) * 1500 * delta;
    CGFloat newYPosition = _crosshair.position.y + (acceleration.y + [[[NSUserDefaults standardUserDefaults] objectForKey:@"calibrationY"] floatValue]) * 1500 * delta;
    
    newXPosition = clampf(newXPosition, 0, bbSize.width);
    newYPosition = clampf(newYPosition, 0, bbSize.height);
    _crosshair.position = CGPointMake(newXPosition, newYPosition);
    
    // score label color changes
    if(score >= 50) {
        _scoreLabel.color = [CCColor blueColor];
    }
    if(score >= 100) {
        _scoreLabel.color = [CCColor orangeColor];
    }
    if(score >= 150) {
        _scoreLabel.color = [CCColor yellowColor];
    }
    if(score >= 200) {
        _scoreLabel.color = [CCColor redColor];
    }
    if(score >= 250 ) {
        _scoreLabel.color = [CCColor purpleColor];
    }
    if(score >= 300) {
        _scoreLabel.color = [CCColor magentaColor];
    }
    
    // timer only starts after the game starts
    if(1 == [[[NSUserDefaults standardUserDefaults] objectForKey:@"Start"] integerValue]) {
        _timerCover.position = ccp(_timerCover.position.x, _timerCover.position.y - 0.2 );
        if(_timerCover.position.y <= 10){
            [self endGame];
        }
    }
}

-(void)calibrate {
    _crosshair.position = ccp(bbSize.width/2, bbSize.height/2);
    float calibrationX = -_motionManager.accelerometerData.acceleration.x;
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithFloat:calibrationX] forKey:@"calibrationX"];
    float calibrationY = -_motionManager.accelerometerData.acceleration.y;
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithFloat:calibrationY] forKey:@"calibrationY"];
    _calibrateButton.visible = false;
    _clickShootLabel.visible = true;
    _arrowLabel.visible = true;
}

- (void)ccPhysicsCollisionPostSolve:(CCPhysicsCollisionPair *)pair ball:(CCNode *)nodeA wall:(CCNode *)nodeB {
    [self endGame];
}

-(void)endGame {
    NSNumber *highScore = [[NSUserDefaults standardUserDefaults] objectForKey:@"HighScore"];
    NSNumber *prevScore = [NSNumber numberWithInt:score];
    if(prevScore.intValue > highScore.intValue) {
        // new highscore
        highScore = prevScore;
        [[NSUserDefaults standardUserDefaults] setObject:highScore forKey:@"HighScore"];
    }
    [[NSUserDefaults standardUserDefaults] setObject:prevScore forKey:@"PreviousScore"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    // change scenes
    CCScene *recapScene = [CCBReader loadAsScene:@"Recap"];
    [[CCDirector sharedDirector] replaceScene:recapScene];
}

@end
