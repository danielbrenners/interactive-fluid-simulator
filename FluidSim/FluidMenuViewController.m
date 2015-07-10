//
//  FluidMenuViewController.m
//  FluidSim
//
//  Created by Michael hein on 10/10/13.
//  Copyright (c) 2013 self. All rights reserved.
//

#import "FluidMenuViewController.h"
#import "FluidGLViewController.h"
#import "Fluid.h"

@interface FluidMenuViewController ()
{
    BOOL keyboardShown;
}

@property (strong, nonatomic) IBOutlet UIView *view;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@property (weak, nonatomic) IBOutlet UITextField *textLowDens;
@property (weak, nonatomic) IBOutlet UITextField *textHighDens;
@property (weak, nonatomic) IBOutlet UITextField *textDiff;
@property (weak, nonatomic) IBOutlet UITextField *textVisc;

@property (weak, nonatomic) IBOutlet UITextField *textColorR;
@property (weak, nonatomic) IBOutlet UITextField *textColorG;
@property (weak, nonatomic) IBOutlet UITextField *textColorB;
@property (weak, nonatomic) IBOutlet UITextField *textColorA;

@property (weak, nonatomic) IBOutlet UITextField *textBoundX;
@property (weak, nonatomic) IBOutlet UITextField *textBoundY;
@property (weak, nonatomic) IBOutlet UITextField *textBoundWidth;
@property (weak, nonatomic) IBOutlet UITextField *textBoundHeight;

@property (weak, nonatomic) IBOutlet UILabel *labelBoundCount;

@property (weak, nonatomic) IBOutlet UITextField *textModelWidth;
@property (weak, nonatomic) IBOutlet UITextField *textModelHeight;
@property (weak, nonatomic) IBOutlet UILabel *labelValidity;
@property (weak, nonatomic) IBOutlet UILabel *labelWidthValue;
@property (weak, nonatomic) IBOutlet UILabel *labelHeightValue;

@property (nonatomic) BOOL isFluidValid;

- (IBAction)actionCreateFluid:(id)sender;
- (IBAction)actionAddBound:(id)sender;
- (IBAction)actionBegin:(id)sender;

@property (strong, atomic) Fluid *fluid;

@end

@implementation FluidMenuViewController

@synthesize fluid = fluid;

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
    self.isFluidValid = NO;
    [self setTitle:@"Menu"];
	// Do any additional setup after loading the view.
}

- (void)viewDidAppear:(BOOL)animated
{
    [self.scrollView setDelegate:self];
    [self.scrollView setScrollEnabled:YES];
    [self.scrollView setContentSize:CGSizeMake(self.scrollView.bounds.size.width, 700)];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)keyboardDidShow:(NSNotification *)notification
{
    if (keyboardShown) {
        return;
    }
    
    
    [self.scrollView setScrollEnabled:YES];
    NSDictionary *info = [notification userInfo];
    NSValue *frameBeginValue = [info objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGSize keyboardSize = [frameBeginValue CGRectValue].size;
    CGRect viewFrame = [self.scrollView frame];
    viewFrame.size.height -= keyboardSize.height;
    [[self scrollView]setFrame:viewFrame];
    
    [[self scrollView]scrollRectToVisible:CGRectMake(0.0, 0.0, self.view.bounds.size.width, self.view.bounds.size.height) animated:YES];
    keyboardShown = YES;
}


- (void)keyboardDidHide:(NSNotification *)notification
{
    NSDictionary* info = [notification userInfo];
    NSValue *frameBeginValue = [info objectForKey:UIKeyboardFrameBeginUserInfoKey];
    CGSize keyboardSize = [frameBeginValue CGRectValue].size;
    CGRect viewFrame = [self.scrollView frame];
    viewFrame.size.height += keyboardSize.height;
    viewFrame = [[UIScreen mainScreen]bounds];
    [[self scrollView]setFrame:viewFrame];
    [self.scrollView scrollRectToVisible:viewFrame animated:YES];
    keyboardShown = NO;
    [self.scrollView setScrollEnabled:NO];
}


- (BOOL)textFieldShouldReturn:(UITextField*)theTextField
{
    [theTextField resignFirstResponder];
    return YES;
}

- (IBAction)actionCreateFluid:(id)sender {
    int m = [self.textModelWidth.text intValue];
    int n = [self.textModelHeight.text intValue];
    if (m>0 && n>0) {
        fluid = [[Fluid alloc]initWithWidth:m Height:n];
        
        
        self.isFluidValid = YES;
        [self.labelValidity setText:@"Valid"];
        [self.labelValidity setTextColor:[UIColor greenColor]];
        [self.labelWidthValue setText:[NSString stringWithFormat:@"%d",m]];
        [self.labelHeightValue setText:[NSString stringWithFormat:@"%d",n]];
        [self.labelBoundCount setText:@"0"];
    }
    
}

- (IBAction)actionAddBound:(id)sender {
    if (!self.isFluidValid) {
        int m = [self.textModelWidth.text intValue];
        int n = [self.textModelHeight.text intValue];
        if (m>0 && n>0) {
            fluid = [[Fluid alloc]initWithWidth:m Height:n];
            self.isFluidValid = YES;
            [self.labelValidity setText:@"Valid"];
            [self.labelValidity setTextColor:[UIColor greenColor]];
            [self.labelWidthValue setText:[NSString stringWithFormat:@"%d",m]];
            [self.labelHeightValue setText:[NSString stringWithFormat:@"%d",n]];
            [self.labelBoundCount setText:@"0"];
        }
    }
    
    int x = [self.textBoundX.text intValue];
    int y = [self.textBoundY.text intValue];
    int width = [self.textBoundWidth.text intValue];
    int height = [self.textBoundHeight.text intValue];
    if (x>0 && y>0 && x+width<fluid.m+2 && y+width<fluid.n+2 && width>2 && height>2) {
        addBound(fluid.m, fluid.n, x, y, width, height, fluid.bounds, fluid.dens, fluid.u, fluid.v);
        int count = [self.labelBoundCount.text intValue];
        count ++;
        [self.labelBoundCount setText:[NSString stringWithFormat:@"%d",count]];
    }
}

- (IBAction)actionBegin:(id)sender {
    if (!self.isFluidValid) {
        int m = [self.textModelWidth.text intValue];
        int n = [self.textModelHeight.text intValue];
        if (m>0 && n>0) {
            fluid = [[Fluid alloc]initWithWidth:m Height:n];
            self.isFluidValid = YES;
            [self.labelValidity setText:@"Valid"];
            [self.labelValidity setTextColor:[UIColor greenColor]];
            [self.labelWidthValue setText:[NSString stringWithFormat:@"%d",m]];
            [self.labelHeightValue setText:[NSString stringWithFormat:@"%d",n]];
            [self.labelBoundCount setText:@"0"];
        }
    }
    
    
    [fluid setDiff:[self.textDiff.text floatValue]];
    [fluid setVisc:[self.textVisc.text floatValue]];
    float fluidColor[4] = {[self.textColorR.text floatValue], [self.textColorG.text floatValue], [self.textColorB.text floatValue], [self.textColorA.text floatValue]};
    [fluid setColor:fluidColor];
    
    [fluid addRandomDensities];
    
    
    FluidGLViewController *GLVC = [[FluidGLViewController alloc]initWithNibName:@"FluidGLView" bundle:[NSBundle mainBundle]fluid:fluid];
    [self presentViewController:GLVC animated:YES completion:nil];
}




@end
