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

// Make readwrite
@property (nonatomic, strong, readwrite) UILabel *floatingLabel;

@end

@implementation RPFloatingPlaceholderTextField

#pragma mark - Programmatic Initializer

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Setup the view defaults
        [self setupViewDefaults];
        [self setupDefaultColorStates];
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
    
    // This must be done in awakeFromNib since global tint color isn't set by the time initWithCoder: is called
    [self setupDefaultColorStates];
    
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
    [self textFieldTextDidChange:nil];
}

- (void)setTextAlignment:(NSTextAlignment)textAlignment
{
    [super setTextAlignment: textAlignment];
    self.floatingLabel.textAlignment = textAlignment;
}

- (void)setPlaceholder:(NSString *)aPlaceholder
{
    if ([self.cachedPlaceholder isEqualToString:aPlaceholder]) return;
    
    // We draw the placeholder ourselves so we can control when it is shown
    // during the animations
    [super setPlaceholder:nil];
    
    self.cachedPlaceholder = aPlaceholder;
    
    self.floatingLabel.text = self.cachedPlaceholder;
    [self adjustFramesForNewPlaceholder];
    
    // Flags the view to redraw
    [self setNeedsDisplay];
}

- (void)setFloatingLabelActiveTextColor:(UIColor *)floatingLabelActiveTextColor
{
    _floatingLabelActiveTextColor = floatingLabelActiveTextColor;
    if (self.isEditing)
        self.floatingLabel.textColor = floatingLabelActiveTextColor;
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
    
    // Forces drawRect to be called when the bounds change
    self.contentMode = UIViewContentModeRedraw;

    // Set the default animation direction
    self.animationDirection = RPFloatingPlaceholderAnimateUpward;
    
    // Create the floating label instance and add it to the view
    self.floatingLabel = [[UILabel alloc] init];
    self.floatingLabel.font = [UIFont boldSystemFontOfSize:11.f];
    self.floatingLabel.textAlignment = self.textAlignment;
    self.floatingLabel.backgroundColor = [UIColor clearColor];
    self.floatingLabel.alpha = 1.f;
    
    // Adjust the top margin of the text field and then cache the original
    // view frame
    self.originalTextFieldFrame = UIEdgeInsetsInsetRect(self.frame, UIEdgeInsetsMake(5.f, 0.f, 2.f, 0.f));
    self.frame = self.originalTextFieldFrame;
    
    // Set the background to a clear color
    self.backgroundColor = [UIColor clearColor];
}

- (void)setupDefaultColorStates {
    // Setup default colors for the floating label states
    UIColor *defaultActiveColor;
    if ([self respondsToSelector:@selector(tintColor)]) {
        defaultActiveColor = self.tintColor ?: [[[UIApplication sharedApplication] delegate] window].tintColor;
    } else {
        // iOS 6
        defaultActiveColor = [UIColor blueColor];
    }
    self.floatingLabelActiveTextColor = self.floatingLabelActiveTextColor ?: defaultActiveColor;
    self.floatingLabelInactiveTextColor = self.floatingLabelInactiveTextColor ?: [UIColor colorWithWhite:0.7f alpha:1.f];
    
    self.floatingLabel.textColor = self.floatingLabelActiveTextColor;
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
    if (self.shouldDrawPlaceholder) {
        UIColor *placeholderGray = self.defaultPlaceholderColor ?: [UIColor colorWithRed:199/255.f green:199/255.f blue:205/255.f alpha:1.f];
        // Inset the placeholder by the same 5px on both sides so that it works in right-to-left languages too
        CGRect placeholderFrame = CGRectMake(5.f, floorf((self.frame.size.height - self.font.lineHeight) / 2.f), self.frame.size.width - 10, self.frame.size.height);
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        [paragraphStyle setAlignment: self.textAlignment];
        
        NSDictionary *placeholderAttributes = @{NSFontAttributeName : self.font,
                                                NSForegroundColorAttributeName : placeholderGray,
                                                NSParagraphStyleAttributeName : paragraphStyle};
        
        if ([self respondsToSelector:@selector(tintColor)]) {
            [self.cachedPlaceholder drawInRect:placeholderFrame
                                withAttributes:placeholderAttributes];
            
        } else {
            NSAttributedString *attributedPlaceholder = [[NSAttributedString alloc] initWithString:self.cachedPlaceholder
                                                                                        attributes:placeholderAttributes];
            [attributedPlaceholder drawInRect:placeholderFrame];
        } // iOS 6
        
    }
}

- (void)didMoveToSuperview
{
    if (self.floatingLabel.superview != self.superview) {
        if (self.superview && self.hasText) {
            [self.superview addSubview:self.floatingLabel];
        } else {
            [self.floatingLabel removeFromSuperview];
        }
    }
}

- (void)showFloatingLabelWithAnimation:(BOOL)isAnimated
{
    // Add it to the superview
    if (self.floatingLabel.superview != self.superview) {
        [self.superview addSubview:self.floatingLabel];
    }
    
    // Flags the view to redraw
    [self setNeedsDisplay];
    
    if (isAnimated) {
        UIViewAnimationOptions options = UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionCurveEaseOut;
        [UIView animateWithDuration:0.2f delay:0.f options:options animations:^{
            self.floatingLabel.alpha = 1.f;
            if (self.animationDirection == RPFloatingPlaceholderAnimateDownward) {
                self.frame = self.offsetTextFieldFrame;
            } else {
                self.floatingLabel.frame = self.offsetFloatingLabelFrame;
            }
        } completion:nil];
    } else {
        self.floatingLabel.alpha = 1.f;
        if (self.animationDirection == RPFloatingPlaceholderAnimateDownward) {
            self.frame = self.offsetTextFieldFrame;
        } else {
            self.floatingLabel.frame = self.offsetFloatingLabelFrame;
        }
    }
}

- (void)hideFloatingLabel
{
    UIViewAnimationOptions options = UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionCurveEaseIn;
    [UIView animateWithDuration:0.2f delay:0.f options:options animations:^{
        self.floatingLabel.alpha = 0.f;
        if (self.animationDirection == RPFloatingPlaceholderAnimateDownward) {
            self.frame = self.originalTextFieldFrame;
        } else {
            self.floatingLabel.frame = self.originalFloatingLabelFrame;
        }
    } completion:^(BOOL finished) {
        // Flags the view to redraw
        [self setNeedsDisplay];
    }];
}

- (void)checkForExistingText
{
    // Check if we need to redraw for pre-existing text
    self.shouldDrawPlaceholder = !self.hasText;
    if (self.hasText) {
        self.floatingLabel.textColor = self.floatingLabelInactiveTextColor;
        [self showFloatingLabelWithAnimation:NO];
    }
}

- (void)adjustFramesForNewPlaceholder
{
    [self.floatingLabel sizeToFit];
    
    CGFloat offset = ceil(self.floatingLabel.font.lineHeight);
    
    self.originalFloatingLabelFrame = CGRectMake(self.originalTextFieldFrame.origin.x + 5.f, self.originalTextFieldFrame.origin.y,
                                                 self.originalTextFieldFrame.size.width - 10.f, self.floatingLabel.frame.size.height);
    self.floatingLabel.frame = self.originalFloatingLabelFrame;
    
    self.offsetFloatingLabelFrame = CGRectMake(self.originalFloatingLabelFrame.origin.x, self.originalFloatingLabelFrame.origin.y - offset,
                                               self.originalFloatingLabelFrame.size.width, self.originalFloatingLabelFrame.size.height);
    
    self.offsetTextFieldFrame = CGRectMake(self.originalTextFieldFrame.origin.x, self.originalTextFieldFrame.origin.y + offset,
                                           self.originalTextFieldFrame.size.width, self.originalTextFieldFrame.size.height);
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
    [UIView transitionWithView:self.floatingLabel duration:0.25 options:options animations:^{
        animationBlock();
    } completion:nil];
}

#pragma mark - Text Field Observers

- (void)textFieldDidBeginEditing:(NSNotification *)notification
{
    __weak __typeof(self) weakSelf = self;
    [self animateFloatingLabelColorChangeWithAnimationBlock:^{
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        _floatingLabel.textColor = strongSelf.floatingLabelActiveTextColor;
    }];
}

- (void)textFieldDidEndEditing:(NSNotification *)notification
{
    __weak __typeof(self) weakSelf = self;
    [self animateFloatingLabelColorChangeWithAnimationBlock:^{
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        self.floatingLabel.textColor = strongSelf.floatingLabelInactiveTextColor;
    }];
}

- (void)textFieldTextDidChange:(NSNotification *)notification
{
    BOOL previousShouldDrawPlaceholderValue = self.shouldDrawPlaceholder;
    self.shouldDrawPlaceholder = !self.hasText;
    
    // Only redraw if self.shouldDrawPlaceholder value was changed
    if (previousShouldDrawPlaceholderValue != self.shouldDrawPlaceholder) {
        if (self.shouldDrawPlaceholder) {
            [self hideFloatingLabel];
        } else {
            [self showFloatingLabelWithAnimation:YES];
        }
    }
}

@end
