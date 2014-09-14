//
//  WWMFace.m
//  Walk With Me
//
//  Created by Derek Schultz on 9/13/14.
//  Copyright (c) 2014 Walk With Me LLC. All rights reserved.
//

#import "WWMFace.h"

@interface WWMFace ()

@property BOOL isWalking;
@property BOOL isVisiting;
@property WWMStatusIndicatorView* indicator;

@end

@implementation WWMFace

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    _isVisiting = NO;
    _isWalking = NO;
    _indicator = [[WWMStatusIndicatorView alloc] init];
    return self;
}

- (id)initWithUser:(NSString*)userID
{
    self = [super init];
    
    self.userClickedFBID = userID;
    
    PFQuery *query = [PFQuery queryWithClassName:@"_User"];
    [query whereKey:@"fbid" equalTo:userID];
    [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        if (!object) {
            NSLog(@"The getFirstObject request failed.");
        } else {
            // The find succeeded.
            self.userClickedFirstName = object[@"firstName"];
            self.userClickedName = object[@"name"];
            self.userClickedHome = object[@"home"];
        }
    }];

    NSString* faceURL = [[NSString alloc] initWithFormat:@"http://graph.facebook.com/%@/picture?type=square&width=100&height=100", userID];
    UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:faceURL]]];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    imageView.layer.cornerRadius = 25;
    imageView.layer.masksToBounds = YES;
    imageView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    imageView.layer.borderWidth = 1.0;
    [self addSubview:imageView];
    [imageView setFrame:CGRectMake(0, 0, 50, 50)];
    
    WWMStatusIndicatorView* statusIndicator = [[WWMStatusIndicatorView alloc] init];
    [self addSubview:statusIndicator];
    [statusIndicator setFrame:CGRectMake(3, 32, 17, 17)];
    
    return self;
}

- (void)ssetIsWalking:(BOOL)isWalking
{
    _isWalking = isWalking;
    [self updateIndicator];
}

- (void)ssetIsVisiting:(BOOL)isVisiting
{
    _isVisiting = isVisiting;
    [self updateIndicator];
}

- (void)updateIndicator {
    if (_isWalking) {
        [_indicator enable];
        [_indicator ssetColor:@"red"];
    }
    else if (_isVisiting) {
        [_indicator enable];
        [_indicator ssetColor:@"green"];
    }
    else {
        [_indicator disable];
    }
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
