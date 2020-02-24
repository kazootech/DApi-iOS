//
//  DriftLayer.m
//  DApiSample
//
//  Created by Jacky Cho on 29/4/2019.
//  Copyright © 2019 Kazoo. All rights reserved.
//

#import "DriftLayer.h"

@implementation DriftLayer {
    CATextLayer *textLayer;
}

-(id) init {
    
    self = [super init];
    if (self) {
        self.bounds = CGRectMake(0, 0, 380, 380);
        self.cornerRadius = 30;
        self.backgroundColor = [UIColor darkGrayColor].CGColor;
        self.delegate = self;
        
        textLayer = [CATextLayer layer];
        textLayer.frame = CGRectMake(-380/2, -30, 380*2, 30);
        textLayer.alignmentMode = kCAAlignmentCenter;
        textLayer.foregroundColor = [UIColor blackColor].CGColor;
        textLayer.fontSize = 16;
        textLayer.delegate = self;
        [self addSublayer:textLayer];
    }
    
    return self;
}


- (void)setText:(NSString *)t {
    textLayer.string = t;
}

- (void)setRotation:(double)r {
    self.transform =  CATransform3DMakeRotation(r, 0.0, 0.0, 1.0);
}


- (id<CAAction>)actionForLayer:(CALayer *)layer forKey:(NSString *)event {
    return (id)[NSNull null];
}


@end
