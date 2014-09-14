//
//  WWMMapViewController.m
//  Walk With Me
//
//  Created by Derek Schultz on 9/12/14.
//  Copyright (c) 2014 Walk With Me LLC. All rights reserved.
//

#import "WWMMapViewController.h"



@interface WWMMapViewController ()

@property BOOL walking;
@property (nonatomic, retain) NSMutableDictionary* faces;
@property (nonatomic, retain) UILabel* fromLabel;

@end

@implementation WWMMapViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Get the size of things
    float frame_width = self.view.frame.size.width;      // 568
    float frame_height = self.view.frame.size.height-64; // 320
    float scan_size = frame_width/5;
    
    // bottom rect
    self.bottomRect = [[UIView alloc] initWithFrame:CGRectMake(0, frame_height+40, frame_width, 340)];
    self.bottomRect.backgroundColor = WWM_LIGHT;
    [self.view addSubview:self.bottomRect];
    
    //ping button
    self.pingBounceButton = [WWMUIButton buttonWithType:UIButtonTypeCustom];
	[self.pingBounceButton addTarget:self action:@selector(pingButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
	[self.pingBounceButton setBackgroundColor:WWM_BLUE];
    [self.pingBounceButton setImage:[UIImage imageNamed:@"PingIcon"] forState:UIControlStateNormal];
    [self.pingBounceButton setImage:[UIImage imageNamed:@"PingIcon"] forState:UIControlStateHighlighted];
	[self.pingBounceButton setFrame:CGRectMake((frame_width-75)/2, frame_height-(75/2), 75, 75)];
	self.pingBounceButton.layer.cornerRadius = 75/2;
	[self.view addSubview:self.pingBounceButton];
    self.pingBounceButton.transform = CGAffineTransformMakeScale(0.7,0.7);

    self.walkBounceButton = [WWMUIButton buttonWithType:UIButtonTypeCustom];
	[self.walkBounceButton addTarget:self action:@selector(startWalk:) forControlEvents:UIControlEventTouchUpInside];
	[self.walkBounceButton setBackgroundColor:WWM_GREEN];
    [self.walkBounceButton setImage:[UIImage imageNamed:@"NavigateStartIcon"] forState:UIControlStateNormal];
    [self.walkBounceButton setImage:[UIImage imageNamed:@"NavigateStartIcon"] forState:UIControlStateHighlighted];
	[self.walkBounceButton setFrame:CGRectMake(50, frame_height-(47/2), 47, 47)];
	self.walkBounceButton.layer.cornerRadius = 47/2;
	[self.view addSubview:self.walkBounceButton];

    // pals button
    self.palsBounceButton = [WWMUIButton buttonWithType:UIButtonTypeCustom];
	[self.palsBounceButton addTarget:self action:@selector(FriendPickerButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
	[self.palsBounceButton setBackgroundColor:WMM_ORANGE];
    [self.palsBounceButton setImage:[UIImage imageNamed:@"PalsIcon"] forState:UIControlStateNormal];
    [self.palsBounceButton setImage:[UIImage imageNamed:@"PalsIcon"] forState:UIControlStateHighlighted];
	[self.palsBounceButton setFrame:CGRectMake(frame_width-50-47, frame_height-(47/2), 47, 47)];
	self.palsBounceButton.layer.cornerRadius = 47/2;
	[self.view addSubview:self.palsBounceButton];
    
    PFUser* currentUser = [PFUser currentUser];
    if (!currentUser) { // No user logged in
        [self performSegueWithIdentifier:@"LoginPrompt" sender:self];
        return;
    }
    [[PFUser currentUser] refresh];
    
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation addUniqueObject:[[NSString alloc] initWithFormat:@"user_%@", PFUser.currentUser[@"fbid"]] forKey:@"channels"];
    [currentInstallation saveInBackground];
    
    self.safetyMap.delegate = self;

    self.firebase = [[Firebase alloc] initWithUrl:FIREBASE_URL];
    Firebase* dependents = [self.firebase childByAppendingPath: [[NSString alloc] initWithFormat:@"users/%@/dependents", currentUser[@"fbid"]]];
    
    _faces = [[NSMutableDictionary alloc] init];
    [dependents observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
        if (!_faces[snapshot.value]) {
            _faces[snapshot.value] = [[WWMFace alloc] initWithUser:snapshot.value];
            [_faces[snapshot.value] ssetIsWalking:YES];
            UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapDat:)];
            [_faces[snapshot.value] addGestureRecognizer:tap];

            [self replaceFaces];
        }
    }];
    
    [dependents observeEventType:FEventTypeChildRemoved withBlock:^(FDataSnapshot *snapshot) {
        [_faces[snapshot.value] removeFromSuperview];
        [_faces removeObjectForKey:snapshot.value];
        [self replaceFaces];
    }];
    
    Firebase* caretakers = [self.firebase childByAppendingPath: [[NSString alloc] initWithFormat:@"users/%@/active_caretakers", currentUser[@"fbid"]]];
    [caretakers observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
        if (!_faces[snapshot.name]) {
            _faces[snapshot.name] = [[WWMFace alloc] initWithUser:snapshot.name];
            [_faces[snapshot.name] ssetIsVisiting:YES];
            [self replaceFaces];
        }
    }];
    [caretakers observeEventType:FEventTypeChildRemoved withBlock:^(FDataSnapshot *snapshot) {
        [_faces[snapshot.name] removeFromSuperview];
        [_faces removeObjectForKey:snapshot.name];
        [self replaceFaces];
    }];


    self.userbase = [self.firebase childByAppendingPath: [[NSString alloc] initWithFormat:@"users/%@",currentUser[@"fbid"]]];
}

- (void)viewDidUnload {
    self.selectedFriendsView = nil;
    self.friendPickerController = nil;
    
    [super viewDidUnload];
}

- (void)tapDat:(UITapGestureRecognizer *)gr {
    UIView *theFaceThatGotTapped = (UIView *)gr.view;
    [self performSegueWithIdentifier: @"BecomeCaretaker" sender: theFaceThatGotTapped];

}

- (void)viewDidAppear:(BOOL)animated {
    [[self navigationController] setNavigationBarHidden:YES animated:animated];
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation {
    if (_walking) {
        [self showRouteHome:userLocation.coordinate];
        Firebase* coords = [self.userbase childByAppendingPath: @"coords"];
        [coords setValue:@[[[NSNumber alloc] initWithDouble:userLocation.coordinate.latitude],
                           [[NSNumber alloc] initWithDouble:userLocation.coordinate.longitude]]];
        
    }
}
        
- (void)replaceFaces {
    uint i = 0;
    for (WWMFace* face in _faces) {
        [self.view addSubview:_faces[face]];
        [_faces[face] setFrame:CGRectMake(self.view.frame.size.width - 10 - (i+1)*60, 25, 50, 50)];
        i++;
    }
}

- (void)showETA {
    [self.fromLabel setText:[[NSString alloc] initWithFormat:@"0:%02.0lf", floor(self.remainingTime / 60)]];
}

- (IBAction)startWalk:(id)sender {
    if (!_walking) {
        
        _walking = YES;
        walkButton.selected = YES;
        
        // ETA Label
        NSString * eta = @"0:21";
        
        
        self.fromLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 40, 320, 100)];
        self.fromLabel.text = eta;
        self.fromLabel.font = [UIFont fontWithName:@"AvenirNext-Regular" size:60];
        self.fromLabel.textAlignment = NSTextAlignmentCenter;

        
        POPSpringAnimation *scaleUp =
        [POPSpringAnimation animationWithPropertyNamed:kPOPViewScaleXY];
        scaleUp.fromValue = [NSValue valueWithCGPoint:CGPointMake(0, 0)];
        scaleUp.toValue = [NSValue valueWithCGPoint:CGPointMake(1.0, 1.0)];
        scaleUp.springBounciness = 15;
        scaleUp.springSpeed = 5.0f;
        
        POPSpringAnimation *pingScaleUp =
        [POPSpringAnimation animationWithPropertyNamed:kPOPViewScaleXY];
        pingScaleUp.toValue = [NSValue valueWithCGPoint:CGPointMake(1.0, 1.0)];
        pingScaleUp.springBounciness = 15;
        pingScaleUp.springSpeed = 5.0f;
        [self.pingBounceButton pop_addAnimation:pingScaleUp forKey:@"scale"];

        
        
        // Delay execution of my block for 10 seconds.
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [self.bottomRect addSubview:self.fromLabel];
            [self.fromLabel pop_addAnimation:scaleUp forKey:@"scale"];
        });
        
        // animate bottom up
        POPSpringAnimation *move = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerPositionY];
		move.toValue = @(450);
		move.springBounciness = 15;
		move.springSpeed = 5.0f;
		[self.bottomRect.layer pop_addAnimation:move forKey:@"position"];
        
        POPSpringAnimation *moveLeft = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerPositionX];
		moveLeft.toValue = @(50);
		moveLeft.springBounciness = 10;
		moveLeft.springSpeed = 5.0f;
		[self.walkBounceButton.layer pop_addAnimation:moveLeft forKey:@"position"];
        
        POPSpringAnimation *moveRight = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerPositionX];
		moveRight.toValue = @(self.view.frame.size.width-49);
		moveRight.springBounciness = 10;
		moveRight.springSpeed = 5.0f;
		[self.palsBounceButton.layer pop_addAnimation:moveRight forKey:@"position"];
        
        // Show destination + route
        [self showRouteHome:self.safetyMap.userLocation.coordinate];
        self.destAnnotation = [[MKPointAnnotation alloc]init];
        [self.destAnnotation setCoordinate:CLLocationCoordinate2DMake([PFUser.currentUser[@"home"][0] doubleValue],
                                                                 [PFUser.currentUser[@"home"][1] doubleValue])];
        [self.destAnnotation setTitle:@"Home"];
        [self.safetyMap addAnnotation:self.destAnnotation];
        
        // Send push notifications and activate walking state for friends
        NSMutableArray* caretakerRefs = [[NSMutableArray alloc] init];

        for (NSString* friend in PFUser.currentUser[@"friends"]) {
            // Push notification
            PFPush *push = [[PFPush alloc] init];
            [push setChannel:[[NSString alloc] initWithFormat:@"user_%@", friend]];
            [push setMessage:[[NSString alloc] initWithFormat:@"%@ is walking home.", PFUser.currentUser[@"name"]]];
            [push sendPushInBackground];
            
            // Add state for caretakers
            Firebase* dependents = [self.firebase childByAppendingPath:[[NSString alloc] initWithFormat:@"users/%@/dependents", friend]];
            Firebase* insertion = [dependents childByAutoId];
            [insertion setValue:PFUser.currentUser[@"fbid"]];
            [caretakerRefs addObject:@[friend, insertion.name]];
        }
        PFUser.currentUser[@"caretakerRefs"] = caretakerRefs;
        [PFUser.currentUser saveInBackground];
    }
    else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"End Walk"
                                                        message:@"Have you arrived safely at your destination?"
                                                       delegate:self
                                              cancelButtonTitle:@"Yes"
                                              otherButtonTitles:@"Cancel", nil];
        [alert show];
    }
}

- (void)endWalk
{
    _walking = NO;
    walkButton.selected = NO;
    
    POPSpringAnimation *move = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerPositionY];
    move.toValue = @(self.view.frame.size.height+150);
    move.springBounciness = 15;
    move.springSpeed = 5.0f;
    [self.bottomRect.layer pop_addAnimation:move forKey:@"position"];
    
    POPSpringAnimation *moveBackLeft = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerPositionX];
    moveBackLeft.toValue = @(60);
    moveBackLeft.springBounciness = 10;
    moveBackLeft.springSpeed = 5.0f;
    [self.walkBounceButton.layer pop_addAnimation:moveBackLeft forKey:@"position"];
    
    POPSpringAnimation *moveBackRight = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerPositionX];
    moveBackRight.toValue = @(self.view.frame.size.width-15-47);
    moveBackRight.springBounciness = 10;
    moveBackRight.springSpeed = 5.0f;
    [self.palsBounceButton.layer pop_addAnimation:moveBackRight forKey:@"position"];
    
    POPSpringAnimation *pingScaleBack =
    [POPSpringAnimation animationWithPropertyNamed:kPOPViewScaleXY];
    pingScaleBack.toValue = [NSValue valueWithCGPoint:CGPointMake(0.7, 0.7)];
    pingScaleBack.springBounciness = 15;
    pingScaleBack.springSpeed = 10.0f;
    [self.pingBounceButton pop_addAnimation:pingScaleBack forKey:@"scale"];
    
    [self.fromLabel removeFromSuperview];
    
    // Send push notifications and deactivate watching friends
    for (NSArray* caretakerRef in PFUser.currentUser[@"caretakerRefs"]) {
        // Push notification
        PFPush *push = [[PFPush alloc] init];
        [push setChannel:[[NSString alloc] initWithFormat:@"user_%@", caretakerRef[0]]];
        [push setMessage:[[NSString alloc] initWithFormat:@"%@ has arrived safely.", PFUser.currentUser[@"name"]]];
        [push sendPushInBackground];
        
        // Turn off all caretakers watching state
        Firebase* dependents = [self.firebase childByAppendingPath:[[NSString alloc] initWithFormat:@"users/%@/dependents", caretakerRef[0]]];
        Firebase* deletion = [dependents childByAppendingPath:caretakerRef[1]];
        [deletion removeValue];
    }
    [self.safetyMap removeAnnotation:self.destAnnotation];
    [self.safetyMap removeOverlay:(self.routeLine)];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        [self endWalk];
    }
}

- (IBAction)unwindToMap:(UIStoryboardSegue *)unwindSegue
{
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(WWMFace*)sender
{
    if ([[segue identifier] isEqualToString:@"BecomeCaretaker"]) {
        
        // Get destination view
        WWMCaretakerViewController *vc = [segue destinationViewController];
        
        // Get button tag number (or do whatever you need to do here, based on your object
        NSLog(@"poo%@", sender);
        // Pass the information to your destination view
        [vc setWalkerFBID:sender.userClickedFBID];
        [vc setWalkerName:sender.userClickedName];
        [vc setWalkerFirstName:sender.userClickedFirstName];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)pingButtonClicked:(id)sender {
    for (NSString* friend in PFUser.currentUser[@"friends"]) {
        // Push notification
        PFPush *push = [[PFPush alloc] init];
        [push setChannel:[[NSString alloc] initWithFormat:@"user_%@", friend]];
        [push setMessage:[[NSString alloc] initWithFormat:@"Ping from %@.  Call?", PFUser.currentUser[@"name"]]];
        [push sendPushInBackground];
    }

}

- (void)FriendPickerButtonClicked:(id)sender {
    
    // if the session is open, then load the data for our view controller
    if (!FBSession.activeSession.isOpen) {
        // if the session is closed, then we open it here, and establish a handler for state changes
        [FBSession openActiveSessionWithReadPermissions:@[@"public_profile", @"user_friends"]
                                           allowLoginUI:YES
                                      completionHandler:^(FBSession *session,
                                                          FBSessionState state,
                                                          NSError *error) {
                                          if (error) {
                                              UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                                                  message:error.localizedDescription
                                                                                                 delegate:nil
                                                                                        cancelButtonTitle:@"OK"
                                                                                        otherButtonTitles:nil];
                                              [alertView show];
                                          } else if (session.isOpen) {
                                              [self FriendPickerButtonClicked:sender];
                                          }
                                      }];
        return;
    }
    
    if (self.friendPickerController == nil) {
        // Create friend picker, and get data loaded into it.
        self.friendPickerController = [[FBFriendPickerViewController alloc] init];
        self.friendPickerController.title = @"My Pals";
        self.friendPickerController.delegate = self;
        self.friendPickerController.allowsMultipleSelection = YES;
        // apparently even if we don't add the constraint that we only show friends with the app,
        // it is still restricted
        //self.friendPickerController.fieldsForRequest = [NSSet setWithObject:@"installed"];
    }
    
    [self.friendPickerController loadData];
    [self.friendPickerController clearSelection];
    [[UIBarButtonItem appearance] setTintColor:WWM_WHITISH];
    NSMutableArray *results = [[NSMutableArray alloc] init];
    [[PFUser currentUser] refresh];

    for (id<FBGraphUser> user_data in PFUser.currentUser[@"friend_profiles"]) {
        NSString *name = user_data[@"name"];
        id<FBGraphUser> user = (id<FBGraphUser>)[FBGraphObject graphObject];
        [user setObjectID:user_data[@"id"]];
        [user setName:name]; // This is not mandatory
        [user setFirst_name:user_data[@"first_name"]];
        [user setLast_name:user_data[@"last_name"]];
        if (user) {
            NSLog(@"adding user: %@", user.name);
            [results addObject:user];
        }
    }
    
    
    // And finally set the selection property
    self.friendPickerController.selection = results;
    [self presentViewController:self.friendPickerController animated:YES completion:nil];
}

- (void)facebookViewControllerDoneWasPressed:(id)sender {
    NSLog(@"Pressed done.");
    
    // we pick up the users from the selection, and create a string that we use to update the text view
    // at the bottom of the display; note that self.selection is a property inherited from our base class
    NSMutableArray *newFriendSelection = [[NSMutableArray alloc] init];
    NSMutableArray *newFriendFBGraphData = [[NSMutableArray alloc] init];
    for (id<FBGraphUser> user in self.friendPickerController.selection) {
        [newFriendSelection addObject:user.objectID];
        [newFriendFBGraphData addObject:user];
    }
    PFUser.currentUser[@"friends"] = newFriendSelection;
    PFUser.currentUser[@"friend_profiles"] = newFriendFBGraphData;
    [[PFUser currentUser] saveInBackground];
    [self dismissViewControllerAnimated:YES completion:NULL];
    
}

- (void)facebookViewControllerCancelWasPressed:(id)sender {
    NSLog(@"Pressed cancel.");
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation
{
    return YES;
}

- (void) mapViewDidFinishRenderingMap:(MKMapView *)mapView fullyRendered:(BOOL)fullyRendered
{
    [mapView setUserTrackingMode:MKUserTrackingModeFollow];
}

@end
