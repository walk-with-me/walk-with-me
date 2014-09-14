//
//  WWMUIButton.m
//  Walk With Me
//
//  Created by Theodore Pak on 9/13/14.
//  Copyright (c) 2014 Walk With Me LLC. All rights reserved.
//

#import "WWMUIButton.h"
#import <pop/POP.h>

@implementation WWMUIButton

- (UIColor *)lighterColorForColor:(UIColor *)c
{
    CGFloat r, g, b, a;
    if ([c getRed:&r green:&g blue:&b alpha:&a])
        return [UIColor colorWithRed:MIN(r + 0.2, 1.0)
                               green:MIN(g + 0.2, 1.0)
                                blue:MIN(b + 0.2, 1.0)
                               alpha:a];
    return nil;
}

- (UIColor *)darkerColorForColor:(UIColor *)c
{
    CGFloat r, g, b, a;
    if ([c getRed:&r green:&g blue:&b alpha:&a])
        return [UIColor colorWithRed:MAX(r - 0.2, 0.0)
                               green:MAX(g - 0.2, 0.0)
                                blue:MAX(b - 0.2, 0.0)
                               alpha:a];
    return nil;
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	POPSpringAnimation *scale = [self pop_animationForKey:@"scale"];
	POPSpringAnimation *color = [self pop_animationForKey:@"color"];
    
    if(color) {
//        color.toValue = [NSValue valueWithCGPoint:CGPointMake(0.8, 0.8)];
    } else {
        self.currentBg = self.backgroundColor;
        color = [POPSpringAnimation animationWithPropertyNamed:kPOPViewBackgroundColor];
        color.toValue = [self darkerColorForColor:self.currentBg];
        color.springBounciness = 10;
        color.springSpeed = 8.0f;
        [self pop_addAnimation:color forKey:@"colorChange"];
    }
    
    
    
	if (scale) {
		scale.toValue = [NSValue valueWithCGPoint:CGPointMake(0.8, 0.8)];
	} else {
		scale = [POPSpringAnimation animationWithPropertyNamed:kPOPViewScaleXY];
		scale.toValue = [NSValue valueWithCGPoint:CGPointMake(0.8, 0.8)];
		scale.springBounciness = 10;
		scale.springSpeed = 18.0f;
		[self pop_addAnimation:scale forKey:@"scale"];
	}
	
	[super touchesBegan:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	POPSpringAnimation *scale = [self pop_animationForKey:@"scale"];
	POPSpringAnimation *color = [self pop_animationForKey:@"color"];
    
    if(color) {
        //        color.toValue = [NSValue valueWithCGPoint:CGPointMake(0.8, 0.8)];
    } else {
        color = [POPSpringAnimation animationWithPropertyNamed:kPOPViewBackgroundColor];
        color.toValue = self.currentBg;
        color.springBounciness = 10;
        color.springSpeed = 8.0f;
        [self pop_addAnimation:color forKey:@"colorChange"];
    }

    
	if (scale) {
		scale.toValue = [NSValue valueWithCGPoint:CGPointMake(1.0, 1.0)];
	} else {
		scale = [POPSpringAnimation animationWithPropertyNamed:kPOPViewScaleXY];
		scale.toValue = [NSValue valueWithCGPoint:CGPointMake(1.0, 1.0)];
		scale.springBounciness = 10;
		scale.springSpeed = 18.0f;
		[self pop_addAnimation:scale forKey:@"scale"];
	}
	
	[super touchesEnded:touches withEvent:event];
}
@end