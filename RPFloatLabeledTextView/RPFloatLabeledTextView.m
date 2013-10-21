//
//  RPFloatLabeledTextView.m
//  RPFloatLabeledTextView
//
//  Created by Rob Phillips on 10/19/13.
//  Copyright (c) 2013 Rob Phillips. All rights reserved.
//
//  See LICENSE for full license agreement.
//

#import "RPFloatLabeledTextView.h"

@interface RPFloatLabeledTextView ()

/**
 Used to draw the placeholder string if necessary.
 */
@property (nonatomic, assign) BOOL shouldDrawPlaceholder;

/**
 Used to know if the text view already exists in the superview.
 */
@property (nonatomic, assign) BOOL existsInSuperview;

/**
 Frames used to animate the floating label and text view into place.
 */
@property (nonatomic, assign) CGRect originalTextViewFrame;
@property (nonatomic, assign) CGRect offsetTextViewFrame;

@end

@implementation RPFloatLabeledTextView

#pragma mark - Programmatic Initializer

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Setup the view defaults
        [self setupViewDefaults];
    }
    return self;
}

#pragma mark - Nib/Storyboard Initializers

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Setup the view defaults
        [self setupViewDefaults];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    // Remember to set the placeholder text via User Defined Runtime
    // Attributes in Interface Builder for the placeholder property to be
    // automatically set here.
    //
    // Example: http://i.imgur.com/Oq1uFt0.png
    //
    //NSLog(@"Placeholder was set in IB to: %@", self.placeholder);
}

#pragma mark - Unsupported Initializers

- (instancetype)init {
    [NSException raise:NSInvalidArgumentException format:@"%s Using the %@ initializer directly is not supported. Use %@ instead.", __PRETTY_FUNCTION__, NSStringFromSelector(@selector(init)), NSStringFromSelector(@selector(initWithFrame:))];
    return nil;
}

#pragma mark - Dealloc

- (void)dealloc
{
    // Remove the text view observers
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Setters & Getters

- (void)setText:(NSString *)text
{
    [super setText:text];
    
    // Check if we need to redraw for pre-existing text
    [self checkForExistingText];
}

- (void)setPlaceholder:(NSString *)aPlaceholder
{
    if ([_placeholder isEqualToString:aPlaceholder]) return;
    
    _placeholder = aPlaceholder;
    
    _floatingLabel.text = _placeholder;
    [self adjustFramesForNewPlaceholder];
}

// This method was deprecated in iOS 6.1+, so we replicate it here
- (BOOL)hasText
{
    return self.text.length != 0;
}

#pragma mark - View Defaults

- (void)setupViewDefaults
{
    // Add observers for the text view state changes
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textViewDidBeginEditing:)
                                                 name:UITextViewTextDidBeginEditingNotification object:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textViewDidEndEditing:)
                                                 name:UITextViewTextDidEndEditingNotification object:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textViewTextDidChange:)
                                                 name:UITextViewTextDidChangeNotification object:self];
    
    // Setup default colors for the floating label states
    self.floatingLabelActiveTextColor = self.tintColor;
    self.floatingLabelInactiveTextColor = [UIColor grayColor];
    
    // Create the floating label instance and add it to the text view
    _floatingLabel = [[UILabel alloc] init];
    _floatingLabel.font = [UIFont boldSystemFontOfSize:11.0f];
    _floatingLabel.textColor = self.floatingLabelActiveTextColor;
    _floatingLabel.backgroundColor = [UIColor clearColor];
    _floatingLabel.alpha = 0.f;
    
    // Change content inset to decrease margin between floating label and
    // text view text
    self.contentInset = UIEdgeInsetsMake(-10.f, 0.f, 0.f, 0.f);
    
    // Cache the original text view frame
    _originalTextViewFrame = self.frame;
    
    // Set the background to a clear color
    self.backgroundColor = [UIColor clearColor];
}

#pragma mark - Drawing & Animations

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    // Check if we need to redraw for pre-existing text
    if (![self isFirstResponder]) {
        [self checkForExistingText];
    }
}

- (void)drawRect:(CGRect)aRect
{
    [super drawRect:aRect];
    
    // Check if we should draw the placeholder string.
    // According to the UITextField docs, placeholders are drawn using
    // a 70% gray color so we will do the same here.
    if (_shouldDrawPlaceholder) {
        UIColor *placeholderGray = [UIColor colorWithWhite:0.7f alpha:1.f];
        [_placeholder drawInRect:CGRectMake(5.0f, 8.0f, self.frame.size.width - 16.0f, self.frame.size.height - 16.0f)
                  withAttributes:@{NSFontAttributeName : self.font,
                                   NSForegroundColorAttributeName : placeholderGray}];
    }
}

- (void)showFloatingLabelWithAnimation:(BOOL)isAnimated
{
    // Add it to the superview so that the floating label does not
    // scroll with the text view contents
    if (!_existsInSuperview) {
        [self.superview addSubview:_floatingLabel];
        _existsInSuperview = YES;
    }
    
    // Flags the view to redraw
    [self setNeedsDisplay];
    
    if (isAnimated) {
        __weak typeof(self) weakSelf = self;
        UIViewAnimationOptions options = UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionCurveEaseOut;
        [UIView animateWithDuration:0.2f delay:0.0f options:options animations:^{
            _floatingLabel.alpha = 1.0f;
            weakSelf.frame = _offsetTextViewFrame;
        } completion:nil];
    } else {
        _floatingLabel.alpha = 1.0f;
        self.frame = _offsetTextViewFrame;
    }
}

- (void)hideFloatingLabel
{
    __weak typeof(self) weakSelf = self;
    UIViewAnimationOptions options = UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionCurveEaseIn;
    [UIView animateWithDuration:0.2f delay:0.0f options:options animations:^{
        _floatingLabel.alpha = 0.0f;
        weakSelf.frame = _originalTextViewFrame;
    } completion:^(BOOL finished) {
        // Flags the view to redraw
        [weakSelf setNeedsDisplay];
    }];
}

- (void)checkForExistingText
{
    // Check if we need to redraw for pre-existing text
    _shouldDrawPlaceholder = !self.hasText;
    if (self.hasText) {
        _floatingLabel.textColor = self.floatingLabelInactiveTextColor;
        [self showFloatingLabelWithAnimation:NO];
    }
}

- (void)adjustFramesForNewPlaceholder
{
    [_floatingLabel sizeToFit];
    
    CGRect originalFloatingLabelFrame = CGRectMake(_originalTextViewFrame.origin.x + 5.f, _originalTextViewFrame.origin.y,
                                                   _originalTextViewFrame.size.width - 16.0f, _floatingLabel.frame.size.height);
    _floatingLabel.frame = originalFloatingLabelFrame;
    
    CGFloat offset = (_floatingLabel.frame.size.height / 3.f) + 10.f;
    _offsetTextViewFrame = CGRectMake(_originalTextViewFrame.origin.x, _originalTextViewFrame.origin.y + offset,
                                      _originalTextViewFrame.size.width, _originalTextViewFrame.size.height - offset);
}

#pragma mark - Text View Observers

- (void)textViewDidBeginEditing:(NSNotification *)notification
{
    _floatingLabel.textColor = self.floatingLabelActiveTextColor;
}

- (void)textViewDidEndEditing:(NSNotification *)notification
{
    _floatingLabel.textColor = self.floatingLabelInactiveTextColor;
}

- (void)textViewTextDidChange:(NSNotification *)notification
{
    BOOL _previousShouldDrawPlaceholderValue = _shouldDrawPlaceholder;
    _shouldDrawPlaceholder = !self.hasText;
    
    // Only redraw if _shouldDrawPlaceholder value was changed
    if (_previousShouldDrawPlaceholderValue != _shouldDrawPlaceholder) {
        if (_shouldDrawPlaceholder) {
            [self hideFloatingLabel];
        } else {
            [self showFloatingLabelWithAnimation:YES];
        }
    }
}

@end
