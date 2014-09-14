//
//  WWMCaretakerViewController.m
//  Walk With Me
//
//  Created by Derek Schultz on 9/13/14.
//  Copyright (c) 2014 Walk With Me LLC. All rights reserved.
//

#import "WWMCaretakerViewController.h"

@interface WWMCaretakerViewController ()

@end

@implementation WWMCaretakerViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
- (IBAction)CallButtonPressed:(id)sender {
    NSString *phoneNumber = [@"telprompt://" stringByAppendingString:@"2679871157"];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:phoneNumber]];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // "Call" button
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Call"
                                                                              style:UIBarButtonItemStylePlain target:self action:@selector(CallButtonPressed:)];
    
    
    self.safetyMap.delegate = self;
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(enteredBackground:)
                                                 name: @"didEnterBackground"
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(enteredForeground:)
                                                 name: @"didEnterForeground"
                                               object: nil];
    
}

- (void)viewDidAppear:(BOOL)animated {
    [[self navigationController] setNavigationBarHidden:NO animated:YES];
    [self.navigationController.navigationBar.topItem setTitle:[[NSString alloc] initWithFormat: @"%@'s Walk",self.walkerFirstName]];
    
    self.firebase = [[Firebase alloc] initWithUrl:FIREBASE_URL];
    self.userbase = [self.firebase childByAppendingPath: [[NSString alloc] initWithFormat:@"users/%@", self.walkerFBID]];
    
    PFQuery *query = [PFQuery queryWithClassName:@"_User"];
    [query whereKey:@"fbid" equalTo:self.walkerFBID];
    [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        if (!object) {
            NSLog(@"The getFirstObject request failed.");
        } else {
            Firebase* coords = [self.userbase childByAppendingPath: @"coords"];
            MKPointAnnotation *otherUser = [[MKPointAnnotation alloc]init];
            [otherUser setCoordinate:CLLocationCoordinate2DMake([object[@"home"][0] doubleValue], [object[@"home"][1] doubleValue])];
            [otherUser setTitle:self.walkerName];
            [self.safetyMap addAnnotation:otherUser];
            [coords observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
                if (snapshot != nil) {
                    NSLog(@"%@",snapshot);
                    CLLocationCoordinate2D other_coords = CLLocationCoordinate2DMake([snapshot.value[0] doubleValue], [snapshot.value[1] doubleValue]);
                    CLLocationCoordinate2D end_coords = CLLocationCoordinate2DMake([object[@"home"][0] doubleValue], [object[@"home"][1] doubleValue]);
                    [otherUser setCoordinate:other_coords];
                    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(other_coords, 500, 500);
                    MKCoordinateRegion adjustedRegion = [self.safetyMap regionThatFits:viewRegion];
                    [self.safetyMap setRegion:adjustedRegion animated:YES];
                    [self showRoute:other_coords :end_coords];
                    
                }
            } withCancelBlock:^(NSError *error) {
                NSLog(@"%@", error.description);
            }];
            
            [self notifyFirebaseWatching];

        }
    }];

}

- (void)showETA {}

- (void) enteredBackground:(NSNotification*) notification
{
    [self notifyFirebaseNoLongerWatching];
}

- (void) enteredForeground:(NSNotification*) notification
{
    [self notifyFirebaseWatching];
}

- (void) viewDidDisappear:(BOOL)animated
{
    [self notifyFirebaseNoLongerWatching];
}

- (void) notifyFirebaseNoLongerWatching
{
    Firebase* users_base = [self.firebase childByAppendingPath: @"users" ];
    Firebase* walker_base = [users_base childByAppendingPath: self.walkerFBID];
    Firebase* walker_caretakers = [walker_base childByAppendingPath:@"active_caretakers"];
    Firebase* new_caretaker = [walker_caretakers childByAppendingPath:[PFUser currentUser][@"fbid"]];
    
    [new_caretaker setValue: nil];

}

- (void) notifyFirebaseWatching
{
    // add current user's fb id to the walker's active caretakers list
    Firebase* users_base = [self.firebase childByAppendingPath: @"users" ];
    Firebase* walker_base = [users_base childByAppendingPath: self.walkerFBID];
    Firebase* walker_caretakers = [walker_base childByAppendingPath:@"active_caretakers"];
    Firebase* new_caretaker = [walker_caretakers childByAppendingPath:[PFUser currentUser][@"fbid"]];

    [new_caretaker setValue: [[NSNumber alloc] initWithInt:1]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) mapViewDidFinishRenderingMap:(MKMapView *)mapView fullyRendered:(BOOL)fullyRendered
{
    
}



/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
