//
//  WWMStatusIndicatorView.m
//  Walk With Me
//
//  Created by Derek Schultz on 9/13/14.
//  Copyright (c) 2014 Walk With Me LLC. All rights reserved.
//

#import "WWMStatusIndicatorView.h"

@interface WWMStatusIndicatorView ()

@property (nonatomic, strong) NSString* color;
@property (nonatomic, assign) BOOL enabled;

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

- (void)disable
{
    _enabled = NO;
    [self setNeedsDisplay];
}

- (void)enable
{
    _enabled = YES;
    [self setNeedsDisplay];
}


- (void)ssetColor:(NSString*)color
{
    self.color = color;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    if (_enabled) {
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSetLineWidth(context, 0.7);
        if ([self.color isEqualToString:@"red"]) {
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
}

@end
