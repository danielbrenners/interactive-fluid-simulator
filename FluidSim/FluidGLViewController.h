//
//  FluidGLViewController.h
//  FluidSim
//
//  Created by Michael hein on 9/24/13.
//  Copyright (c) 2013 self. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

@class Fluid;

@interface FluidGLViewController : GLKViewController <UIGestureRecognizerDelegate>
// the <...> syntax causes this class to adopt the protocols listed
// some Objective-C classes adopt certain protocols by default, listed in docs
// this protocol allows FluidGLViewControllers to be delegates for UIGestureRecognizers
// to actually be used as a delegate, the "delegate functions" must be implemented in the class implementation
// see the documentation for UIGestureRecognizerDelegate for a list of useable (and potentially required) functions


@property (strong, atomic) Fluid *fluid;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil fluid:(Fluid*)fluidIn;

@end
