//
//  WWMMapViewController.m
//  Walk With Me
//
//  Created by Derek Schultz on 9/12/14.
//  Copyright (c) 2014 Walk With Me LLC. All rights reserved.
//

#import "WWMMapViewController.h"

@interface WWMMapViewController ()

@property (strong, nonatomic) Firebase* firebase;
@property (strong, nonatomic) Firebase* usersbase;
@property (strong, nonatomic) Firebase* userbase;
@property BOOL walking;

@end

@implementation WWMMapViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[self navigationController] setNavigationBarHidden:YES animated:NO];

    PFUser* currentUser = [PFUser currentUser];
    if (!currentUser) { // No user logged in
        [self performSegueWithIdentifier:@"LoginPrompt" sender:self];
        return;
    }
    [[PFUser currentUser] refresh];
    
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation addUniqueObject:[[NSString alloc] initWithFormat:@"user_%@", PFUser.currentUser.objectId] forKey:@"channels"];
    [currentInstallation saveInBackground];
    
    self.safetyMap.delegate = self;

    _firebase = [[Firebase alloc] initWithUrl:FIREBASE_URL];
    _usersbase = [_firebase childByAppendingPath: @"users"];
    NSLog(@"%@", currentUser);
    _userbase = [_firebase childByAppendingPath: currentUser.objectId];
}

- (void)viewDidUnload {
    self.selectedFriendsView = nil;
    self.friendPickerController = nil;
    
    [super viewDidUnload];
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay {
    // this dictates the style of the navigation route
    if ([overlay isKindOfClass:[MKPolyline class]]) {
        MKPolylineRenderer* aView = [[MKPolylineRenderer alloc] initWithPolyline:(MKPolyline*)overlay];
        aView.strokeColor = [[UIColor blueColor] colorWithAlphaComponent:0.5];
        aView.lineWidth = 10;
        return aView;
    }
    return nil;
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation {
    if (_walking) {
        [self showRouteHome:userLocation];
    }
}

- (void)showRouteHome:(MKUserLocation*)userLocation {
    // set the source to the current location
    NSLog(@"%f", userLocation.coordinate.latitude);
    MKPlacemark *source = [[MKPlacemark alloc] initWithCoordinate:userLocation.coordinate
                                                addressDictionary:[NSDictionary dictionaryWithObjectsAndKeys:@"", @"", nil]];
    
    Firebase* coords = [_userbase childByAppendingPath: @"coords"];
    [coords setValue:@[[[NSNumber alloc] initWithDouble:source.coordinate.latitude],
                       [[NSNumber alloc] initWithDouble:source.coordinate.longitude]]];
    
    
    MKMapItem *srcMapItem = [[MKMapItem alloc] initWithPlacemark:source];
    [srcMapItem setName:@""];
    
    // set the destination to a hardcoded one
    // TODO change this to the user's home
    MKPlacemark *destination = [[MKPlacemark alloc] initWithCoordinate:CLLocationCoordinate2DMake([PFUser.currentUser[@"home"][0] doubleValue],
                                   [PFUser.currentUser[@"home"][1] doubleValue])
                                                     addressDictionary:[NSDictionary dictionaryWithObjectsAndKeys:@"",@"", nil]];
    NSLog(@"%f", destination.coordinate.latitude);
    MKMapItem *distMapItem = [[MKMapItem alloc] initWithPlacemark:destination];
    [distMapItem setName:@""];
    
    // get the directions
    MKDirectionsRequest *request = [[MKDirectionsRequest alloc]init];
    [request setSource:srcMapItem];
    [request setDestination:distMapItem];
    [request setTransportType:MKDirectionsTransportTypeWalking];
    
    MKDirections *direction = [[MKDirections alloc]initWithRequest:request];
    
    [direction calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse *response, NSError *error) {
        NSLog(@"response = %@",response);
        NSArray *arrRoutes = [response routes];
        [arrRoutes enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            
            MKRoute *route = obj;
            
            // alter the map overlay to reflect the new route
            [_safetyMap removeOverlay:(self.routeLine)];
            self.routeLine = [route polyline];
            [_safetyMap addOverlay:self.routeLine];
            NSLog(@"Route Name : %@",route.name);
            NSLog(@"Total Distance (in Meters) :%f", route.distance);
            
            NSArray *steps = [route steps];
            
            [steps enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                NSLog(@"Route Instruction : %@",[obj instructions]);
                NSLog(@"Route Distance : %f",[obj distance]);
            }];
        }];
    }];
}

- (void) mapViewDidFinishRenderingMap:(MKMapView *)mapView fullyRendered:(BOOL)fullyRendered
{
    if (true) {
        [mapView setUserTrackingMode:MKUserTrackingModeFollow];
    }
    else {
        Firebase* coords = [_userbase childByAppendingPath: @"coords"];
        MKPointAnnotation *otherUser = [[MKPointAnnotation alloc]init];
        [otherUser setCoordinate:CLLocationCoordinate2DMake(39.9500, -75.1900)];
        [otherUser setTitle:@"Other dude"];
        [mapView addAnnotation:otherUser];
        [coords observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
            NSLog(@"%@", snapshot.value);
            if (snapshot.value) {
                [otherUser setCoordinate:CLLocationCoordinate2DMake([snapshot.value[0] doubleValue],
                                                                    [snapshot.value[1] doubleValue])];
            }
        } withCancelBlock:^(NSError *error) {
            NSLog(@"%@", error.description);
        }];
    }
}

- (IBAction)startWalk:(id)sender {
    _walking = YES;
    [self showRouteHome:_safetyMap.userLocation];
    MKPointAnnotation *destAnnotation = [[MKPointAnnotation alloc]init];
    [destAnnotation setCoordinate:CLLocationCoordinate2DMake([PFUser.currentUser[@"home"][0] doubleValue],
                                                             [PFUser.currentUser[@"home"][1] doubleValue])];
    [destAnnotation setTitle:@"Destination"]; //You can set the subtitle too
    [_safetyMap addAnnotation:destAnnotation];
    
    // SEND EM ALL DEM NOTIFICACIONES
    for (NSString* friend in PFUser.currentUser[@"friends"]) {
        PFPush *push = [[PFPush alloc] init];
        [push setChannel:[[NSString alloc] initWithFormat:@"user_%@", friend]];
        [push setMessage:[[NSString alloc] initWithFormat:@"%@ is walking home.", PFUser.currentUser[@"name"]]];
        [push sendPushInBackground];
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
    NSMutableString *text = [[NSMutableString alloc] init];
    
    // we pick up the users from the selection, and create a string that we use to update the text view
    // at the bottom of the display; note that self.selection is a property inherited from our base class
    for (id<FBGraphUser> user in self.friendPickerController.selection) {
        if ([text length]) {
            [text appendString:@", "];
        }
        [text appendString:user.name];
        NSLog(@"%@", text);
    }
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
