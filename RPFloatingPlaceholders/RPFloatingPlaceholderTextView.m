//
//  RPFloatingPlaceholderTextView.m
//  RPFloatingPlaceholders
//
//  Created by Rob Phillips on 10/19/13.
//  Copyright (c) 2013 Rob Phillips. All rights reserved.
//
//  See LICENSE for full license agreement.
//

#import "RPFloatingPlaceholderTextView.h"

@interface RPFloatingPlaceholderTextView ()

/**
 Used to draw the placeholder string if necessary.
 */
@property (nonatomic, assign) BOOL shouldDrawPlaceholder;

/**
 Frames used to animate the floating label and text view into place.
 */
@property (nonatomic, assign) CGRect originalTextViewFrame;
@property (nonatomic, assign) CGRect offsetTextViewFrame;
@property (nonatomic, assign) CGRect originalFloatingLabelFrame;
@property (nonatomic, assign) CGRect offsetFloatingLabelFrame;

@end

@implementation RPFloatingPlaceholderTextView

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
    
    // Ensures that the placeholder & text are set through our custom setters
    // when loaded from a nib/storyboard.
    self.placeholder = self.placeholder;
    self.text = self.text;
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
    
    // Set the default animation direction
    self.animationDirection = RPFloatingPlaceholderAnimateUpward;
    
    // Setup default colors for the floating label states
    self.floatingLabelActiveTextColor = self.tintColor;
    self.floatingLabelInactiveTextColor = [UIColor colorWithWhite:0.7f alpha:1.f];;
    
    // Create the floating label instance and add it to the text view
    _floatingLabel = [[UILabel alloc] init];
    _floatingLabel.font = [UIFont boldSystemFontOfSize:11.f];
    _floatingLabel.textColor = self.floatingLabelActiveTextColor;
    _floatingLabel.backgroundColor = [UIColor clearColor];
    _floatingLabel.alpha = 0.f;
    
    // Change content inset to decrease margin between floating label and
    // text view text
    self.contentInset = UIEdgeInsetsMake(-10.f, 0.f, 0.f, 0.f);
    
    // Fixes a vertical alignment issue when setting text at runtime
    self.textContainerInset = UIEdgeInsetsMake(10.f, 0.f, 0.f, 0.f);
    
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
    // Use RGB values found via Photoshop for placeholder color #c7c7cd.
    if (_shouldDrawPlaceholder) {
        UIColor *placeholderGray = [UIColor colorWithRed:199/255.f green:199/255.f blue:205/255.f alpha:1.f];
        [_placeholder drawInRect:CGRectMake(5.f, 10.f, self.frame.size.width - 10.f, self.frame.size.height - 20.f)
                  withAttributes:@{NSFontAttributeName : self.font,
                                   NSForegroundColorAttributeName : placeholderGray}];
    }
}

- (void)showFloatingLabelWithAnimation:(BOOL)isAnimated
{
    // Add it to the superview so that the floating label does not
    // scroll with the text view contents
    if (!_floatingLabel.superview) {
        [self.superview addSubview:_floatingLabel];
    }
    
    // Flags the view to redraw
    [self setNeedsDisplay];
    
    if (isAnimated) {
        __weak typeof(self) weakSelf = self;
        UIViewAnimationOptions options = UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionCurveEaseOut;
        [UIView animateWithDuration:0.2f delay:0.f options:options animations:^{
            _floatingLabel.alpha = 1.f;
            if (weakSelf.animationDirection == RPFloatingPlaceholderAnimateDownward) {
                weakSelf.frame = _offsetTextViewFrame;
            } else {
                _floatingLabel.frame = _offsetFloatingLabelFrame;
            }
        } completion:nil];
    } else {
        _floatingLabel.alpha = 1.f;
        if (self.animationDirection == RPFloatingPlaceholderAnimateDownward) {
            self.frame = _offsetTextViewFrame;
        } else {
            _floatingLabel.frame = _offsetFloatingLabelFrame;
        }
    }
}

- (void)hideFloatingLabel
{
    __weak typeof(self) weakSelf = self;
    UIViewAnimationOptions options = UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionCurveEaseIn;
    [UIView animateWithDuration:0.2f delay:0.f options:options animations:^{
        _floatingLabel.alpha = 0.f;
        if (weakSelf.animationDirection == RPFloatingPlaceholderAnimateDownward) {
            weakSelf.frame = _originalTextViewFrame;
        } else {
            _floatingLabel.frame = _originalFloatingLabelFrame;
        }
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
    
    CGFloat offset = _floatingLabel.font.lineHeight;
    
    _originalFloatingLabelFrame = CGRectMake(_originalTextViewFrame.origin.x + 5.f, _originalTextViewFrame.origin.y,
                                                   _originalTextViewFrame.size.width - 10.f, _floatingLabel.frame.size.height);
    _floatingLabel.frame = _originalFloatingLabelFrame;
    
    _offsetFloatingLabelFrame = CGRectMake(_originalFloatingLabelFrame.origin.x, _originalFloatingLabelFrame.origin.y - offset,
                                           _originalFloatingLabelFrame.size.width, _originalFloatingLabelFrame.size.height);
    
    _offsetTextViewFrame = CGRectMake(_originalTextViewFrame.origin.x, _originalTextViewFrame.origin.y + offset,
                                      _originalTextViewFrame.size.width, _originalTextViewFrame.size.height - offset);
}

- (void)animateFloatingLabelColorChangeWithAnimationBlock:(void (^)(void))animationBlock
{
    UIViewAnimationOptions options = UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionTransitionCrossDissolve;
    [UIView transitionWithView:_floatingLabel duration:0.25 options:options animations:^{
        animationBlock();
    } completion:nil];
}

#pragma mark - Text View Observers

- (void)textViewDidBeginEditing:(NSNotification *)notification
{
    __weak typeof(self) weakSelf = self;
    [self animateFloatingLabelColorChangeWithAnimationBlock:^{
        _floatingLabel.textColor = weakSelf.floatingLabelActiveTextColor;
    }];
}

- (void)textViewDidEndEditing:(NSNotification *)notification
{
    __weak typeof(self) weakSelf = self;
    [self animateFloatingLabelColorChangeWithAnimationBlock:^{
        _floatingLabel.textColor = weakSelf.floatingLabelInactiveTextColor;
    }];
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
