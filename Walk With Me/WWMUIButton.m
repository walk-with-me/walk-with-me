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

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	POPSpringAnimation *scale = [self pop_animationForKey:@"scale"];
	
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