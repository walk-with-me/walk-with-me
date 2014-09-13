//
//  WWMViewController.h
//  Walk With Me
//
//  Created by Derek Schultz on 9/12/14.
//  Copyright (c) 2014 Walk With Me LLC. All rights reserved.
//

#import "WalkWithMe.h"

@interface WWMViewController : UIViewController <MKMapViewDelegate>
@property (weak, nonatomic) IBOutlet MKMapView *safetyMap;
@property (weak, nonatomic) MKPolyline *routeLine;

@end
