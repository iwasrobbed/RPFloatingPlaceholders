//
//  ViewController.m
//  FloatLabeledTextViewExample
//
//  Created by Rob Phillips on 10/19/13.
//  Copyright (c) 2013 Rob Phillips. All rights reserved.
//

#import "ViewController.h"
#import "RPFloatLabeledTextView.h"

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the code below to add a text view programmatically
    /**
    CGRect frame = CGRectMake(20.f, 20.f, 273.f, 95.f);
    RPFloatLabeledTextView *flTextView = [[RPFloatLabeledTextView alloc] initWithFrame:frame];
    flTextView.floatingLabelActiveTextColor = [UIColor blueColor];
    flTextView.floatingLabelInactiveTextColor = [UIColor grayColor];
    flTextView.placeholder = @"Tell me about yourself";
    flTextView.font = [UIFont fontWithName:@"Helvetica" size:16.f];
    //flTextView.text = @"I love lamp"; // You can set text after it's been initialized
    [self.view addSubview:flTextView];
     */
}

- (IBAction)dismissKeyboard:(id)sender
{
    [self.view endEditing:YES];
}

@end
