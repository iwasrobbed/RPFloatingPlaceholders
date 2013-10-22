//
//  ViewController.m
//  FloatLabeledTextViewExample
//
//  Created by Rob Phillips on 10/19/13.
//  Copyright (c) 2013 Rob Phillips. All rights reserved.
//

#import "ViewController.h"
#import "RPFloatingPlaceholderTextField.h"
#import "RPFloatingPlaceholderTextView.h"

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the code below to add a text field programmatically
    /**
    CGRect frame = CGRectMake(20.f, 20.f, 273.f, 30.f);
    RPFloatingPlaceholderTextField *flTextField = [[RPFloatingPlaceholderTextField alloc] initWithFrame:frame];
    flTextField.floatingLabelActiveTextColor = [UIColor blueColor];
    flTextField.floatingLabelInactiveTextColor = [UIColor grayColor];
    flTextField.placeholder = @"This is a single-line text field";
    flTextField.font = [UIFont fontWithName:@"Helvetica" size:16.f];
    //flTextField.animationDirection = RPFloatingPlaceholderAnimateDownward; // You can change animation direction
    //flTextField.text = @"I love lamp."; // You can set text after it's been initialized
    [self.view addSubview:flTextField];
     */
    
    // Uncomment the code below to add a text view programmatically
    /**
    CGRect frame2 = CGRectMake(20.f, 76.f, 273.f, 95.f);
    RPFloatingPlaceholderTextView *flTextView = [[RPFloatingPlaceholderTextView alloc] initWithFrame:frame2];
    flTextView.floatingLabelActiveTextColor = [UIColor blueColor];
    flTextView.floatingLabelInactiveTextColor = [UIColor grayColor];
    flTextView.placeholder = @"Tell me about yourself";
    flTextView.font = [UIFont fontWithName:@"Helvetica" size:16.f];
    //flTextView.text = @"I love lamp.  This is pre-existing text."; // You can set text after it's been initialized
    [self.view addSubview:flTextView];
     */
}

- (IBAction)dismissKeyboard:(id)sender
{
    [self.view endEditing:YES];
}

@end
