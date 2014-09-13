//
//  WWMCaretakerViewController.h
//  Walk With Me
//
//  Created by Derek Schultz on 9/13/14.
//  Copyright (c) 2014 Walk With Me LLC. All rights reserved.
//

#import "WalkWithMe.h"

@interface WWMCaretakerViewController : WWMSafetyMapViewController <MKMapViewDelegate>

@property (weak, nonatomic) IBOutlet MKMapView * safetyMap;

@end
