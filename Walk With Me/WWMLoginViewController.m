//
//  WWMLoginViewController.m
//  Walk With Me
//
//  Created by Derek Schultz on 9/13/14.
//  Copyright (c) 2014 Walk With Me LLC. All rights reserved.
//

#import "WWMLoginViewController.h"
#import <FacebookSDK/FacebookSDK.h>

@interface WWMLoginViewController ()

@end

@implementation WWMLoginViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
- (IBAction)login:(id)sender {
    NSArray *permissions = [[NSArray alloc] initWithObjects:@"user_friends", nil];
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
                    user[@"firstName"] = userData[@"first_name"];
                    user[@"lastName"] = userData[@"last_name"];
                    user[@"name"] = userData[@"name"];
                    user[@"fbid"] = userData[@"id"];
                    if (!user[@"home"]) {
                        user[@"home"] = @[[[NSNumber alloc] initWithDouble:0], [[NSNumber alloc] initWithDouble:0]];
                    }
                    [user saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                        [self performSegueWithIdentifier:@"LoginSuccess" sender:self];
                    }];
                }
            }];

        }
    }];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Facebook login button, aligned vertically and horizontally.
//    FBLoginView *loginView = [[FBLoginView alloc] init];
//    loginView.frame = CGRectOffset(loginView.frame, (self.view.center.x - (loginView.frame.size.width / 2)),
//                                                    (self.view.center.y - (loginView.frame.size.height / 2)));
//    [self.view addSubview:loginView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
