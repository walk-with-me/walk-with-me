//
//  WWMStatusIndicatorView.m
//  Walk With Me
//
//  Created by Derek Schultz on 9/13/14.
//  Copyright (c) 2014 Walk With Me LLC. All rights reserved.
//

#import "WWMStatusIndicatorView.h"

@interface WWMStatusIndicatorView ()

@end

@implementation WWMStatusIndicatorView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setBackgroundColor:[UIColor clearColor]];
    }
    return self;
}
- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, 0.7);
    if (self.parentFace.isWalking) {
        CGContextSetFillColor(context, CGColorGetComponents(WWM_RED.CGColor));
    }
    else {
        CGContextSetFillColor(context, CGColorGetComponents(WWM_GREEN.CGColor));
    }
    CGContextSetStrokeColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextClip(context);
    CGRect rectangle = CGRectMake(0, 0, 12, 12);
    CGContextFillEllipseInRect(context, rectangle);
    CGContextStrokeEllipseInRect(context, rectangle);
}

@end
