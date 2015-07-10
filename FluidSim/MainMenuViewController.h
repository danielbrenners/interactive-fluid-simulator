//
//  MainMenuViewController.h
//  FluidSim
//
//  Created by Michael hein on 10/10/13.
//  Copyright (c) 2013 self. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MainMenuViewController : UIViewController

@property (strong, nonatomic) IBOutlet UIView *view;

@property (weak, nonatomic, readonly) NSMutableArray *buttons;
@property (weak, nonatomic, readonly) NSMutableArray *textFields;
@property (weak, nonatomic, readonly) NSMutableArray *labels;


- (void)setBackgroundImage:(UIImage*)image;
- (void)setTitleImage:(UIImage*)image;

- (void)addButton:(UIButton*)button;

@end
