//
//  RPFloatingPlaceholderTextField.m
//  RPFloatingPlaceholders
//
//  Created by Rob Phillips on 10/19/13.
//  Copyright (c) 2013 Rob Phillips. All rights reserved.
//
//  See LICENSE for full license agreement.
//

#import "RPFloatingPlaceholderTextField.h"

@interface RPFloatingPlaceholderTextField ()

/**
 Used to cache the placeholder string.
 */
@property (nonatomic, strong) NSString *cachedPlaceholder;

/**
 Used to draw the placeholder string if necessary.
 */
@property (nonatomic, assign) BOOL shouldDrawPlaceholder;

/**
 Frames used to animate the floating label and text field into place.
 */
@property (nonatomic, assign) CGRect originalTextFieldFrame;
@property (nonatomic, assign) CGRect offsetTextFieldFrame;
@property (nonatomic, assign) CGRect originalFloatingLabelFrame;
@property (nonatomic, assign) CGRect offsetFloatingLabelFrame;

@end

@implementation RPFloatingPlaceholderTextField

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
    if ([_cachedPlaceholder isEqualToString:aPlaceholder]) return;
    
    // We draw the placeholder ourselves so we can control when it is shown
    // during the animations
    [super setPlaceholder:nil];
    
    _cachedPlaceholder = aPlaceholder;
    
    _floatingLabel.text = _cachedPlaceholder;
    [self adjustFramesForNewPlaceholder];
    
    // Flags the view to redraw
    [self setNeedsDisplay];
}

- (BOOL)hasText
{
    return self.text.length != 0;
}

#pragma mark - View Defaults

- (void)setupViewDefaults
{
    // Add observers for the text field state changes
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldDidBeginEditing:)
                                                 name:UITextFieldTextDidBeginEditingNotification object:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldDidEndEditing:)
                                                 name:UITextFieldTextDidEndEditingNotification object:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldTextDidChange:)
                                                 name:UITextFieldTextDidChangeNotification object:self];
    
    // Set the default animation direction
    self.animationDirection = RPFloatingPlaceholderAnimateUpward;
    
    // Setup default colors for the floating label states
    self.floatingLabelActiveTextColor = self.tintColor;
    self.floatingLabelInactiveTextColor = [UIColor colorWithWhite:0.7f alpha:1.f];
    
    // Create the floating label instance and add it to the view
    _floatingLabel = [[UILabel alloc] init];
    _floatingLabel.font = [UIFont boldSystemFontOfSize:11.f];
    _floatingLabel.textColor = self.floatingLabelActiveTextColor;
    _floatingLabel.backgroundColor = [UIColor clearColor];
    _floatingLabel.alpha = 1.f;

    // Adjust the top margin of the text field and then cache the original
    // view frame
    _originalTextFieldFrame = UIEdgeInsetsInsetRect(self.frame, UIEdgeInsetsMake(5.f, 0.f, 2.f, 0.f));
    self.frame = _originalTextFieldFrame;
    
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
        [_cachedPlaceholder drawInRect:CGRectMake(5.f, 0.f, self.frame.size.width, self.frame.size.height)
                        withAttributes:@{NSFontAttributeName : self.font,
                                         NSForegroundColorAttributeName : placeholderGray}];
    }
}

- (void)showFloatingLabelWithAnimation:(BOOL)isAnimated
{
    // Add it to the superview
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
                weakSelf.frame = _offsetTextFieldFrame;
            } else {
                _floatingLabel.frame = _offsetFloatingLabelFrame;
            }
        } completion:nil];
    } else {
        _floatingLabel.alpha = 1.f;
        if (self.animationDirection == RPFloatingPlaceholderAnimateDownward) {
            self.frame = _offsetTextFieldFrame;
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
            weakSelf.frame = _originalTextFieldFrame;
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
    
    _originalFloatingLabelFrame = CGRectMake(_originalTextFieldFrame.origin.x + 5.f, _originalTextFieldFrame.origin.y,
                                                   _originalTextFieldFrame.size.width - 10.f, _floatingLabel.frame.size.height);
    _floatingLabel.frame = _originalFloatingLabelFrame;
    
    _offsetFloatingLabelFrame = CGRectMake(_originalFloatingLabelFrame.origin.x, _originalFloatingLabelFrame.origin.y - offset,
                                           _originalFloatingLabelFrame.size.width, _originalFloatingLabelFrame.size.height);
    
    _offsetTextFieldFrame = CGRectMake(_originalTextFieldFrame.origin.x, _originalTextFieldFrame.origin.y + offset,
                                       _originalTextFieldFrame.size.width, _originalTextFieldFrame.size.height);
}

// Adds padding so these text fields align with RPFloatingPlaceholderTextView's
- (CGRect)textRectForBounds:(CGRect)bounds
{
    return [super textRectForBounds:UIEdgeInsetsInsetRect(bounds, UIEdgeInsetsMake(0.f, 5.f, 0.f, 5.f))];
}

// Adds padding so these text fields align with RPFloatingPlaceholderTextView's
- (CGRect)editingRectForBounds:(CGRect)bounds
{
    return [super editingRectForBounds:UIEdgeInsetsInsetRect(bounds, UIEdgeInsetsMake(0.f, 5.f, 0.f, 5.f))];
}

- (void)animateFloatingLabelColorChangeWithAnimationBlock:(void (^)(void))animationBlock
{
    UIViewAnimationOptions options = UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionTransitionCrossDissolve;
    [UIView transitionWithView:_floatingLabel duration:0.25 options:options animations:^{
        animationBlock();
    } completion:nil];
}

#pragma mark - Text Field Observers

- (void)textFieldDidBeginEditing:(NSNotification *)notification
{
    __weak typeof(self) weakSelf = self;
    [self animateFloatingLabelColorChangeWithAnimationBlock:^{
        _floatingLabel.textColor = weakSelf.floatingLabelActiveTextColor;
    }];
}

- (void)textFieldDidEndEditing:(NSNotification *)notification
{
    __weak typeof(self) weakSelf = self;
    [self animateFloatingLabelColorChangeWithAnimationBlock:^{
        _floatingLabel.textColor = weakSelf.floatingLabelInactiveTextColor;
    }];
}

- (void)textFieldTextDidChange:(NSNotification *)notification
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
