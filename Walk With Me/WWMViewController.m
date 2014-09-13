//
//  WWMViewController.m
//  Walk With Me
//
//  Created by Derek Schultz on 9/12/14.
//  Copyright (c) 2014 Walk With Me LLC. All rights reserved.
//

#import "WWMViewController.h"

@interface WWMViewController ()

@end

@implementation WWMViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.safetyMap.delegate = self;
	// Do any additional setup after loading the view, typically from a nib.
    NSArray *permissions = [[NSArray alloc] init];
    [PFFacebookUtils logInWithPermissions:permissions block:^(PFUser *user, NSError *error) {
        if (!user) {
            NSLog(@"Uh oh. The user cancelled the Facebook login.");
        } else {
            
            NSLog(@"User logged in through Facebook!");
            FBRequest *request = [FBRequest requestForMe];
            [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                if (!error) {
                    // result is a dictionary with the user's Facebook data
                    NSDictionary *userData = (NSDictionary *)result;
                    
                    NSString *facebookID = userData[@"id"];
                    NSString *name = userData[@"name"];
                    NSString *location = userData[@"location"][@"name"];
                    NSString *gender = userData[@"gender"];
                    NSString *birthday = userData[@"birthday"];
                    NSString *relationship = userData[@"relationship_status"];
                    
                    NSURL *pictureURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large&return_ssl_resources=1", facebookID]];
                    
                    
                }
            }];

        }
    }];
    
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

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation      {
    
    // set the source to the current location
    MKPlacemark *source = [[MKPlacemark alloc]initWithCoordinate:userLocation.coordinate addressDictionary:[NSDictionary dictionaryWithObjectsAndKeys:@"",@"", nil] ];
    
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
    [mapView setUserTrackingMode:MKUserTrackingModeFollow];
    MKPointAnnotation *destAnnotation = [[MKPointAnnotation alloc]init];
    [destAnnotation setCoordinate:CLLocationCoordinate2DMake(39.9500, -75.1900)];
    [destAnnotation setTitle:@"Destination"]; //You can set the subtitle too
    [mapView addAnnotation:destAnnotation];

}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
