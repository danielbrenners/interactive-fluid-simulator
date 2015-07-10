//
//  FluidAppDelegate.m
//  FluidSim
//
//  Created by Michael hein on 9/24/13.
//  Copyright (c) 2013 self. All rights reserved.
//

#import "FluidAppDelegate.h"
#import "FluidModel.h"
#import "Fluid.h"
#import "FluidTabBarController.h"
#import "FluidGLViewController.h"
#import "FluidMenuViewController.h"

@implementation FluidAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    //setting up the window to display the contents of our view controller's view
    //often call the Apple's "window layer" in docs
    //this is how Mac OSX and and iOS give our app space on the screen to draw on
    //other operating systems can (and often do, in fact) do this differently, although the code to set it up may be similar
    
    FluidMenuViewController *fluidMenuVC = [[FluidMenuViewController alloc]initWithNibName:@"FluidMenuView" bundle:[NSBundle mainBundle]];
    
    [self.window setRootViewController:fluidMenuVC];
    
    
//    Fluid *firstFluid = [[Fluid alloc]initWithWidth:30 Height:50];
//    [firstFluid addRandomDensities];
//    FluidGLViewController *glVC = [[FluidGLViewController alloc]initWithNibName:@"FluidGLView" bundle:[NSBundle mainBundle] fluid:firstFluid];
//    [self.window setRootViewController:glVC];
    
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
