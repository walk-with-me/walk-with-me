    //
//  WWMMapViewController.m
//  Walk With Me
//
//  Created by Derek Schultz on 9/12/14.
//  Copyright (c) 2014 Walk With Me LLC. All rights reserved.
//

#import "WWMMapViewController.h"
#import "WWMCaretakerViewController.h"

@interface WWMMapViewController ()

@property BOOL walking;
@property NSMutableDictionary* faces;

@end

@implementation WWMMapViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Get the size of things
    float frame_width = self.view.frame.size.width;      // 568
    float frame_height = self.view.frame.size.height-64; // 320
    float scan_size = frame_width/5;
    
    // Ping Button
    pingButton = [[UIButton alloc] initWithFrame:CGRectMake((frame_width-75)/2, frame_height-(75/2), 75, 75)];
    pingButton.layer.cornerRadius = 75/2;
    pingButton.clipsToBounds = YES;
    [pingButton setImage:[UIImage imageNamed:@"PingIcon"] forState:UIControlStateNormal];
    [pingButton setBackgroundColor:WWM_BLUE];
    [pingButton addTarget:self action:@selector(pingButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:pingButton];
    
    // Walk Button
    walkButton = [[UIButton alloc] initWithFrame:CGRectMake(40, frame_height-(47/2), 47, 47)];
    walkButton.layer.cornerRadius = 47/2;
    walkButton.clipsToBounds = YES;
    [walkButton setImage:[UIImage imageNamed:@"NavigateStartIcon"] forState:UIControlStateNormal];
    [walkButton setBackgroundColor:WWM_GREEN];
//    [walkButton setTitle:@"Walk" forState:UIControlStateNormal];
//    [walkButton setTitle:@"Stop" forState:UIControlStateSelected];
    [walkButton addTarget:self action:@selector(startWalk:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:walkButton];
    
    // Pals Button
    palsButton = [[UIButton alloc] initWithFrame:CGRectMake(frame_width-40-47, frame_height-(47/2), 47, 47)];
    palsButton.layer.cornerRadius = 47/2;
    palsButton.clipsToBounds = YES;
    [palsButton setImage:[UIImage imageNamed:@"PalsIcon"] forState:UIControlStateNormal];
    [palsButton setBackgroundColor:WMM_ORANGE];
//    [palsButton setTitle:@"Pals" forState:UIControlStateNormal];
    [palsButton addTarget:self action:@selector(FriendPickerButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:palsButton];

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
        if (_faces[snapshot.value]) {
            [_faces[snapshot.value] setIsWalking:YES];
        }
        else {
            _faces[snapshot.value] = [[WWMFace alloc] initWithUser:snapshot.value];
            [_faces[snapshot.value] setIsWalking:YES];
            [self replaceFaces];
        }
    }];
    
    [dependents observeEventType:FEventTypeChildRemoved withBlock:^(FDataSnapshot *snapshot) {
        if ([PFUser.currentUser[@"friends"] indexOfObject:snapshot.value] == NSNotFound) {
            [_faces removeObjectForKey:snapshot.value];
            [self replaceFaces];
        }
        else {
            [_faces[snapshot.value] setIsWalking:NO];
        }
    }];
    self.userbase = [self.firebase childByAppendingPath: [[NSString alloc] initWithFormat:@"users/%@",currentUser[@"fbid"]]];
}

- (void)viewDidUnload {
    self.selectedFriendsView = nil;
    self.friendPickerController = nil;
    
    [super viewDidUnload];
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
        [self.view addSubview:face];
        [face setFrame:CGRectMake(self.view.frame.size.width - 10 - (i+1)*60, 25, 50, 50)];
        i++;
    }
}

- (IBAction)startWalk:(id)sender {
    if (!_walking) {
        
        _walking = YES;
        walkButton.selected = YES;
        
        // Show destination + route
        [self showRouteHome:self.safetyMap.userLocation.coordinate];
        MKPointAnnotation *destAnnotation = [[MKPointAnnotation alloc]init];
        [destAnnotation setCoordinate:CLLocationCoordinate2DMake([PFUser.currentUser[@"home"][0] doubleValue],
                                                                 [PFUser.currentUser[@"home"][1] doubleValue])];
        [destAnnotation setTitle:@"Home"];
        [self.safetyMap addAnnotation:destAnnotation];
        
        // Send push notifications and activate walking state for friends
        uint i = 0;
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

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"BecomeCaretaker"]) {
        
        // Get destination view
        WWMCaretakerViewController *vc = [segue destinationViewController];
        
        // Get button tag number (or do whatever you need to do here, based on your object
        NSString* user_clicked_fbid = @"10204962536286151"; // todo unhardcode Derek's data
        NSString* user_clicked_name = @"Derek Schultz";
        NSString* user_clicked_first_name = @"Derek";
        
        // Pass the information to your destination view
        [vc setWalkerFBID:user_clicked_fbid];
        [vc setWalkerName:user_clicked_name];
        [vc setWalkerFirstName:user_clicked_first_name];
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
