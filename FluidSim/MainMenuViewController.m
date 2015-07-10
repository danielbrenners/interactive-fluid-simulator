//
//  MainMenuViewController.m
//  FluidSim
//
//  Created by Michael hein on 10/10/13.
//  Copyright (c) 2013 self. All rights reserved.
//

#import "MainMenuViewController.h"

@interface MainMenuViewController () {
    
}

@property (weak, nonatomic) IBOutlet UIImageView *backgroundImageView;
@property (weak, nonatomic) IBOutlet UIImageView *titleImageView;

@end




@implementation MainMenuViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - GUI Configuration

- (void)setBackgroundImage:(UIImage*)image
{
    
}

- (void)setTitleImage:(UIImage*)image
{
    
}

- (void)addButton:(UIButton*)button
{
    
}


@end
