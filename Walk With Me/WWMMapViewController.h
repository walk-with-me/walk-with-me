//
//  WWMMapViewController.h
//  Walk With Me
//
//  Created by Derek Schultz on 9/12/14.
//  Copyright (c) 2014 Walk With Me LLC. All rights reserved.
//

#import "WalkWithMe.h"

@interface WWMMapViewController : WWMSafetyMapViewController <MKMapViewDelegate>

@property (weak, nonatomic) IBOutlet MKMapView * safetyMap;
@property (strong, nonatomic) IBOutlet UITextView *selectedFriendsView;
@property (retain, nonatomic) FBFriendPickerViewController *friendPickerController;

- (IBAction)FriendPickerButtonClicked:(id)sender;

@end
