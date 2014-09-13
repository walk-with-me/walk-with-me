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
@property NSMutableArray* faces;

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
    self.usersbase = [self.firebase childByAppendingPath: @"users"];
    NSLog(@"%@", currentUser);
    self.userbase = [self.firebase childByAppendingPath: currentUser[@"fbid"]];
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

- (IBAction)startWalk:(id)sender {
    _walking = YES;
    [self showRouteHome:self.safetyMap.userLocation];
    MKPointAnnotation *destAnnotation = [[MKPointAnnotation alloc]init];
    [destAnnotation setCoordinate:CLLocationCoordinate2DMake([PFUser.currentUser[@"home"][0] doubleValue],
                                                             [PFUser.currentUser[@"home"][1] doubleValue])];
    [destAnnotation setTitle:@"Destination"]; //You can set the subtitle too
    [self.safetyMap addAnnotation:destAnnotation];
    
    // SEND EM ALL DEM NOTIFICACIONES and put at top
    uint i = 0;
    for (NSString* friend in PFUser.currentUser[@"friends"]) {
        PFPush *push = [[PFPush alloc] init];
        [push setChannel:[[NSString alloc] initWithFormat:@"user_%@", friend]];
        [push setMessage:[[NSString alloc] initWithFormat:@"%@ is walking home.", PFUser.currentUser[@"name"]]];
        [push sendPushInBackground];
        
        UIImage* face = [[UIImage alloc] init];
        
        NSString* faceURL = [[NSString alloc] initWithFormat:@"http://graph.facebook.com/%@/picture?type=square&width=100&height=100", friend];
        UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:faceURL]]];
        UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
        imageView.layer.cornerRadius = 25;
        imageView.layer.masksToBounds = YES;
        imageView.layer.borderColor = [UIColor lightGrayColor].CGColor;
        imageView.layer.borderWidth = 2.0;
        [self.view addSubview:imageView];
        [imageView setFrame:CGRectMake(self.view.frame.size.width - 10 - (i+1)*60, 25, 50, 50)];
        i++;
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
    
    [self presentViewController:self.friendPickerController animated:YES completion:nil];
}

- (void)facebookViewControllerDoneWasPressed:(id)sender {
    NSLog(@"Pressed done.");
    
    // we pick up the users from the selection, and create a string that we use to update the text view
    // at the bottom of the display; note that self.selection is a property inherited from our base class
    NSMutableArray *newFriendSelection = [[NSMutableArray alloc] init];
    for (id<FBGraphUser> user in self.friendPickerController.selection) {
        [newFriendSelection addObject:user.objectID];
    }
    PFUser.currentUser[@"friends"] = newFriendSelection;
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
