//
//  WWMMapViewController.h
//  Walk With Me
//
//  Created by Derek Schultz on 9/12/14.
//  Copyright (c) 2014 Walk With Me LLC. All rights reserved.
//

#import "WalkWithMe.h"
#import "WWMSafetyMapViewController.h"
#import "WWMCaretakerViewController.h"
#import "WWMUIButton.h"
#import "WWMFace.h"
#import <pop/POP.h>
#import "WWMCaretakerViewController.h"
#import "WWMStatusIndicatorView.h"

@interface WWMMapViewController : WWMSafetyMapViewController <MKMapViewDelegate, UIAlertViewDelegate>
{
    UIButton *pingButton;
    UIButton *navigateButton;
    UIButton *palsButton;
    UIButton *walkButton;
}

@property (strong, nonatomic) IBOutlet UITextView *selectedFriendsView;
@property (retain, nonatomic) FBFriendPickerViewController *friendPickerController;
@property (strong) WWMUIButton *pingBounceButton;
@property (strong) WWMUIButton *walkBounceButton;
@property (strong) WWMUIButton *palsBounceButton;
@property (strong) UIView *bottomRect;
@property MKPointAnnotation *destAnnotation;

- (IBAction)FriendPickerButtonClicked:(id)sender;

@end
