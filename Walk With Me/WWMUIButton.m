//
//  WWMUIButton.m
//  Walk With Me
//
//  Created by Theodore Pak on 9/13/14.
//  Copyright (c) 2014 Walk With Me LLC. All rights reserved.
//

#import "WWMUIButton.h"

@implementation WWMUIButton

+ (UIButton *)ASButtonWithFrame:(CGRect)frame title:(NSString *)title
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.frame = frame;
    UIColor *defaultTintColor = WWM_BLACKISH;
    button.layer.borderWidth = 1;
    //button.layer.borderColor = defaultTintColor.CGColor;
    button.layer.cornerRadius = 50;
    button.layer.masksToBounds = YES;
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:defaultTintColor forState:UIControlStateNormal];
    [button setTitleColor:WWM_WHITISH forState:UIControlStateHighlighted];
//    UIImage *backGroundImage = [UIImage createSolidColorImageWithColor:defaultTintColor
//                                                               andSize:button.bounds.size];
//    [button setBackgroundImage:backGroundImage forState:UIControlStateHighlighted];
    return button;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
