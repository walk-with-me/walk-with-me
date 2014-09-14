//
//  WWMFace.h
//  Walk With Me
//
//  Created by Derek Schultz on 9/13/14.
//  Copyright (c) 2014 Walk With Me LLC. All rights reserved.
//

#import "WalkWithMe.h"
#import "WWMStatusIndicatorView.h"
@interface WWMFace : UIView

@property NSString* userClickedFBID;
@property NSString* userClickedName;
@property NSString* userClickedFirstName;
@property NSArray* userClickedHome;

@property BOOL isWalking;
@property BOOL isVisiting;


- (id)initWithUser:(NSString*)userID;
- (void)ssetIsWalking:(BOOL)isWalking;
- (void)ssetIsVisiting:(BOOL)isVisiting;

@end
