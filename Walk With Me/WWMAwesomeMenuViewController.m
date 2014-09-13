//
//  WWMAwesomeMenuViewController.m
//  Walk With Me
//
//  Created by Theodore Pak on 9/13/14.
//  Copyright (c) 2014 Walk With Me LLC. All rights reserved.
//

#import "WWMAwesomeMenuViewController.h"
#import "AwesomeMenu.h"
#import "AwesomeMenuItem.h"

@interface WWMAwesomeMenuViewController ()

@end

@implementation WWMAwesomeMenuViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Setup the menu items and then the menu
    UIImage *storyMenuItemImage = [UIImage imageNamed:@"bg-menuitem.png"];
    UIImage *storyMenuItemImagePressed = [UIImage imageNamed:@"bg-menuitem-highlighted.png"];
    UIImage *starImage = [UIImage imageNamed:@"icon-star.png"];
    
    
    AwesomeMenuItem *starMenuItem1 = [[AwesomeMenuItem alloc] initWithImage:storyMenuItemImage
                                                           highlightedImage:storyMenuItemImagePressed
                                                               ContentImage:starImage
                                                    highlightedContentImage:nil];
    AwesomeMenuItem *starMenuItem2 = [[AwesomeMenuItem alloc] initWithImage:storyMenuItemImage
                                                           highlightedImage:storyMenuItemImagePressed
                                                               ContentImage:starImage
                                                    highlightedContentImage:nil];
    
    AwesomeMenuItem *starMenuItem3 = [[AwesomeMenuItem alloc] initWithImage:storyMenuItemImage
                                                           highlightedImage:storyMenuItemImagePressed
                                                               ContentImage:starImage
                                                    highlightedContentImage:nil];
    
    NSArray *menuOptions = [NSArray arrayWithObjects:starMenuItem1, starMenuItem2, starMenuItem3, nil];
    
    AwesomeMenu *menu = [[AwesomeMenu alloc] initWithFrame:self.view.frame
                                                     menus:menuOptions];
    
    // Lower-right Quadrant
    menu.menuWholeAngle = M_PI / 180 * 90;
    menu.rotateAngle = M_PI / 180 * 90;
    
    menu.startPoint = CGPointMake(30.0f, 30.0f);
    
    [self.view addSubview:menu];
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (void)AwesomeMenu:(AwesomeMenu *)menu didSelectIndex:(NSInteger)idx
{
    UIViewController *newVC = [[UIViewController alloc] init];
    newVC.view.backgroundColor = [UIColor whiteColor];
    UILabel *selectedLabel = [[UILabel alloc] initWithFrame:CGRectMake(50.0f, 50.0f, 100.0f, 100.0f)];
    [selectedLabel setText:[NSString stringWithFormat:@"Index Selected: %d", idx]];
    [selectedLabel sizeToFit];
    [newVC.view addSubview:selectedLabel];
    selectedLabel.center = newVC.view.center;
    
    [self presentModalViewController:newVC];
    
    NSLog(@"Select the index : %d",idx);
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
