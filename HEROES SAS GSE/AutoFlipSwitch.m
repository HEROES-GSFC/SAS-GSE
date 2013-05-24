//
//  AutoFlipSwitch.m
//  HEROES SAS GSE
//
//  Created by Steven Christe on 5/21/13.
//  Copyright (c) 2013 GSFC. All rights reserved.
//

#import "AutoFlipSwitch.h"

#define RED_INDICATOR 3
#define ORANGE_INDICATOR 2
#define GREEN_INDICATOR 1

@interface AutoFlipSwitch()
@property (nonatomic, strong) NSTimer *timer;
-(void)FlipOff;
@end

@implementation AutoFlipSwitch

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.timer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(FlipOff) userInfo:nil repeats:NO];
        [self setCriticalValue:RED_INDICATOR];
        [self setWarningValue:ORANGE_INDICATOR];
        [self setMinValue:0];
        [self setMaxValue:1];
    }
    self.intValue = GREEN_INDICATOR;
    return self;
}

- (void)reset{
    [self.timer invalidate];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(FlipOff) userInfo:nil repeats:NO];
}

-(void)FlipOff{
    self.intValue = RED_INDICATOR;
    [self.timer invalidate];
    NSLog(@"done");
}

@end
