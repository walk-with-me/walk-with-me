//
//  WWMFace.h
//  Walk With Me
//
//  Created by Derek Schultz on 9/13/14.
//  Copyright (c) 2014 Walk With Me LLC. All rights reserved.
//

#import "WalkWithMe.h"

@interface WWMFace : UIView

@property NSString* userClickedFBID;
@property NSString* userClickedName;
@property NSString* userClickedFirstName;
@property NSArray* userClickedHome;

- (id)initWithUser:(NSString*)userID;
- (void)setIsWalking:(BOOL)isWalking;
- (void)setIsVisiting:(BOOL)isVisiting;

@end
