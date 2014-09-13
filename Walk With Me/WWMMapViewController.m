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

@end

@implementation WWMMapViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    if (![PFUser currentUser]) { // No user logged in
        [self performSegueWithIdentifier:@"LoginPrompt" sender:self];
    }
    self.safetyMap.delegate = self;
	// Do any additional setup after loading the view, typically from a nib.
    _firebase = [[Firebase alloc] initWithUrl:FIREBASE_URL];
    _usersbase = [_firebase childByAppendingPath: @"users"];
    _userbase = [_firebase childByAppendingPath: @"10241"];
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay {
    // this dictates the style of the navigation route
    if ([overlay isKindOfClass:[MKPolyline class]]) {
        MKPolylineRenderer* aView = [[MKPolylineRenderer alloc]initWithPolyline:(MKPolyline*)overlay] ;
        aView.strokeColor = [[UIColor blueColor] colorWithAlphaComponent:0.5];
        aView.lineWidth = 10;
        return aView;
    }
    return nil;
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation {
    // set the source to the current location
    MKPlacemark *source = [[MKPlacemark alloc]initWithCoordinate:userLocation.coordinate addressDictionary:[NSDictionary dictionaryWithObjectsAndKeys:@"", @"", nil] ];
    
    Firebase* coords = [_userbase childByAppendingPath: @"coords"];
    [coords setValue:@[[[NSNumber alloc] initWithDouble:source.coordinate.latitude],
                       [[NSNumber alloc] initWithDouble:source.coordinate.longitude]]];
    
    
    MKMapItem *srcMapItem = [[MKMapItem alloc]initWithPlacemark:source];
    [srcMapItem setName:@""];
    
    // set the destination to a hardcoded one
    // TODO change this to the user's home
    MKPlacemark *destination = [[MKPlacemark alloc]initWithCoordinate:CLLocationCoordinate2DMake(37.33072, -122.029674) addressDictionary:[NSDictionary dictionaryWithObjectsAndKeys:@"",@"", nil] ];
    
    MKMapItem *distMapItem = [[MKMapItem alloc]initWithPlacemark:destination];
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
            
            MKRoute *rout = obj;
            
            // alter the map overlay to reflect the new route
            [mapView removeOverlay:(self.routeLine)];
            self.routeLine = [rout polyline];
            [mapView addOverlay:self.routeLine];
            NSLog(@"Rout Name : %@",rout.name);
            NSLog(@"Total Distance (in Meters) :%f",rout.distance);
            
            NSArray *steps = [rout steps];
            
            [steps enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                NSLog(@"Rout Instruction : %@",[obj instructions]);
                NSLog(@"Rout Distance : %f",[obj distance]);
            }];
        }];
    }];

}

- (void) mapViewDidFinishRenderingMap:(MKMapView *)mapView fullyRendered:(BOOL)fullyRendered
{
    if (false) {
        [mapView setUserTrackingMode:MKUserTrackingModeFollow];
        MKPointAnnotation *destAnnotation = [[MKPointAnnotation alloc]init];
        [destAnnotation setCoordinate:CLLocationCoordinate2DMake(39.9500, -75.1900)];
        [destAnnotation setTitle:@"Destination"]; //You can set the subtitle too
        [mapView addAnnotation:destAnnotation];
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

- (IBAction)unwindToMap:(UIStoryboardSegue *)unwindSegue
{
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
