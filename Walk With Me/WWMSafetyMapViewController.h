//
//  WWMSafetyMapDelegate.h
//  Walk With Me
//
//  Created by Derek Schultz on 9/13/14.
//  Copyright (c) 2014 Walk With Me LLC. All rights reserved.
//

#import "WalkWithMe.h"

@interface WWMSafetyMapViewController : UIViewController <MKMapViewDelegate>

@property (strong, nonatomic) Firebase* firebase;
@property (strong, nonatomic) Firebase* usersbase;
@property (strong, nonatomic) Firebase* userbase;

@property (weak, nonatomic) MKPolyline *routeLine;
@property (weak, nonatomic) IBOutlet MKMapView *safetyMap;

- (void)showRouteHome:(CLLocationCoordinate2D)userCoordinates;
- (void)showRoute:(CLLocationCoordinate2D)fromCoordinates :(CLLocationCoordinate2D)toCoordinates;

@end
