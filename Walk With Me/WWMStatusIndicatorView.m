//
//  WWMStatusIndicatorView.m
//  Walk With Me
//
//  Created by Derek Schultz on 9/13/14.
//  Copyright (c) 2014 Walk With Me LLC. All rights reserved.
//

#import "WWMStatusIndicatorView.h"

@interface WWMStatusIndicatorView ()

@property UIColor* indicatorColor;

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

- (void)setColor:(UIColor*)color
{
    _indicatorColor = color;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, 1.0);
    CGContextSetFillColor(context, CGColorGetComponents(_indicatorColor.CGColor));
    CGContextSetStrokeColorWithColor(context, [UIColor whiteColor].CGColor);
    CGRect rectangle = CGRectMake(0, 0, 12, 12);
    CGContextClip(context);
    CGContextFillEllipseInRect(context, rectangle);
    CGContextStrokeEllipseInRect(context, rectangle);
}

@end
