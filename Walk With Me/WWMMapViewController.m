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
@property NSMutableDictionary* faces;

@end

@implementation WWMMapViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

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
        [self showRouteHome:userLocation];
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
        
        // Show destination + route
        [self showRouteHome:self.safetyMap.userLocation];
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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
        self.friendPickerController.cancelButton = nil;
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

@end
