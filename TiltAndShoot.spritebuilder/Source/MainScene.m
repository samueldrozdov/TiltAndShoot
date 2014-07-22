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

#import <math.h>


@implementation MainScene {
    CCNode *_instructions;
    CCNode *_ball;
    CCNode *_crosshair;
    CCNode *_pointer;
    CCLabelTTF *_scoreLabel;
    CCPhysicsNode *_physicsNode;
    
    
    CMMotionManager *_motionManager;
    CGSize bbSize;
    float ballRadius;
    int score;
    int power;
    
    float calibrationX;
    float calibrationY;
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
    calibrationX = 0;
    calibrationY = 0;
    ballRadius = 35.5;
    score = 0;
    power = 1;
    
}


// called on every touch in this scene
-(void) touchBegan:(UITouch *)touch withEvent:(UIEvent *)event {
    int ballX = _ball.positionInPoints.x;
    int ballY = _ball.positionInPoints.y;
    int crosshairX = _crosshair.position.x;
    int crosshairY = _crosshair.position.y;
    float crosshairDistToBall = sqrtf(powf(crosshairX - ballX, 2) + powf(crosshairY - ballY, 2));
    
    // check if the ball contains the crosshair
    if(ballRadius >= crosshairDistToBall) {
        _instructions.visible = false;
        _scoreLabel.visible = true;
        score++;
        
        // load particle effect
        CCParticleSystem *hit = (CCParticleSystem *)[CCBReader load:@"HitParticle"];
        // make the particle effect clean itself up, once it is completed
        hit.autoRemoveOnFinish = TRUE;
        // place the particle effect on the ball's position
        hit.position = _ball.positionInPoints;
        [_ball.parent addChild:hit z:-1];
        
        // hitting the ball further from the center applies some more force
        [_ball.physicsBody applyForce:ccp((ballX-crosshairX)*power,(ballY-crosshairY)*power)];
        power += 5;
        
        // decrease and updates the score on the ball
        _scoreLabel.string = [NSString stringWithFormat:@"%d", score];
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
    CGFloat newXPosition = _crosshair.position.x + (acceleration.x+calibrationX) * 1500 * delta;
    CGFloat newYPosition = _crosshair.position.y + (acceleration.y+calibrationY) * 1500 * delta;
       
    newXPosition = clampf(newXPosition, 0, bbSize.width);
    newYPosition = clampf(newYPosition, 0, bbSize.height);
    _crosshair.position = CGPointMake(newXPosition, newYPosition);
    
    
    if(score >= 50) {
        _scoreLabel.color = [CCColor brownColor];
    }
    if(score >= 100) {
        _scoreLabel.color = [CCColor whiteColor];
    }
    if(score >= 150) {
        _scoreLabel.color = [CCColor yellowColor];
    }
    if(score >= 200) {
        _scoreLabel.color = [CCColor redColor];
    }
}

-(void)calibrate {
    _crosshair.position = ccp(bbSize.width/2, bbSize.height/2);
    calibrationX = -_motionManager.accelerometerData.acceleration.x;
    calibrationY = -_motionManager.accelerometerData.acceleration.y;
}

- (void)ccPhysicsCollisionPostSolve:(CCPhysicsCollisionPair *)pair ball:(CCNode *)nodeA wall:(CCNode *)nodeB {
    [self endGame];
}

-(void)endGame {
    NSNumber *highScore = [[NSUserDefaults standardUserDefaults] objectForKey:@"HighScore"];
    NSNumber *prevScore = [NSNumber numberWithInt:score];
    if(prevScore.intValue > highScore.intValue) {
        // new highscore!
        highScore = prevScore;
        [[NSUserDefaults standardUserDefaults] setObject:highScore forKey:@"HighScore"];
    }
    [[NSUserDefaults standardUserDefaults] setObject:prevScore forKey:@"PreviousScore"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    CCScene *recapScene = [CCBReader loadAsScene:@"Recap"];
    [[CCDirector sharedDirector] replaceScene:recapScene];
}

@end
