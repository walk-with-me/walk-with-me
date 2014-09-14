//
//  WWMSafetyMapDelegate.m
//  Walk With Me
//
//  Created by Derek Schultz on 9/13/14.
//  Copyright (c) 2014 Walk With Me LLC. All rights reserved.
//

#import "WWMSafetyMapViewController.h"

@interface WWMSafetyMapViewController ()

@end

@implementation WWMSafetyMapViewController

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay {
    // this dictates the style of the navigation route
    if ([overlay isKindOfClass:[MKPolyline class]]) {
        MKPolylineRenderer* aView = [[MKPolylineRenderer alloc] initWithPolyline:(MKPolyline*)overlay];
        aView.strokeColor = [WWM_BLUE colorWithAlphaComponent:0.5];
        aView.lineWidth = 10;
        return aView;
    }
    return nil;
}
- (void)showRoute:(CLLocationCoordinate2D)fromCoordinates :(CLLocationCoordinate2D)toCoordinates
{
    MKPlacemark *source = [[MKPlacemark alloc] initWithCoordinate:fromCoordinates
                                                addressDictionary:[NSDictionary dictionaryWithObjectsAndKeys:@"", @"", nil]];
    
    MKMapItem *srcMapItem = [[MKMapItem alloc] initWithPlacemark:source];
    [srcMapItem setName:@""];
    
    MKPlacemark *destination = [[MKPlacemark alloc] initWithCoordinate:toCoordinates
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
- (void)showRouteHome:(CLLocationCoordinate2D)userCoordinates {
    [self showRoute:userCoordinates:CLLocationCoordinate2DMake([PFUser.currentUser[@"home"][0] doubleValue],
                                                               [PFUser.currentUser[@"home"][1] doubleValue])];
}

@end
