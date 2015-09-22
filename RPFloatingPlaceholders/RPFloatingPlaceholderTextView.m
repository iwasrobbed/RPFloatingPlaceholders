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

// Make readwrite
@property (nonatomic, strong, readwrite) UILabel *floatingLabel;

@end

@implementation RPFloatingPlaceholderTextView

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

- (instancetype)initWithFrame:(CGRect)frame textContainer:(NSTextContainer *)textContainer
{
    self = [super initWithFrame:frame textContainer:textContainer];
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
    
    // Remember to set the placeholder text via User Defined Runtime
    // Attributes in Interface Builder for the placeholder property to be
    // automatically set here.
    //
    // Example: http://i.imgur.com/Oq1uFt0.png
    //
    //NSLog(@"Placeholder was set in IB to: %@", self.placeholder);
    
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
    [self textViewTextDidChange:nil];
}

- (void)setTextAlignment:(NSTextAlignment)textAlignment
{
    [super setTextAlignment: textAlignment];
    self.floatingLabel.textAlignment = textAlignment;
}

- (void)setPlaceholder:(NSString *)aPlaceholder
{
    if ([_placeholder isEqualToString:aPlaceholder]) return;
    
    _placeholder = aPlaceholder;
    
    self.floatingLabel.text = _placeholder;
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
    
    // Forces drawRect to be called when the bounds change
    self.contentMode = UIViewContentModeRedraw;

    // Set the default animation direction
    self.animationDirection = RPFloatingPlaceholderAnimateUpward;
    
    // Create the floating label instance and add it to the text view
    self.floatingLabel = [[UILabel alloc] init];
    self.floatingLabel.font = [UIFont boldSystemFontOfSize:11.f];
    self.floatingLabel.textAlignment = self.textAlignment;
    self.floatingLabel.backgroundColor = [UIColor clearColor];
    self.floatingLabel.alpha = 0.f;
    
    if ([self respondsToSelector:@selector(textContainerInset)]) {
        // Change content inset to decrease margin between floating label and
        // text view text
        self.contentInset = UIEdgeInsetsMake(-10.f, 0.f, 0.f, 0.f);
    
        // Fixes a vertical alignment issue when setting text at runtime
        self.textContainerInset = UIEdgeInsetsMake(10.f, 0.f, 0.f, 0.f);
    } else {
        // Change content inset to decrease left margin and margin between
        // floating text view text
        self.contentInset = UIEdgeInsetsMake(-8.f, -3.f, 0.f, 0.f);
    }  // iOS 6
    
    // Cache the original text view frame
    self.originalTextViewFrame = self.frame;
    
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
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        [paragraphStyle setAlignment: self.textAlignment];
        
        NSDictionary *placeholderAttributes = @{NSFontAttributeName : self.font,
                                                NSForegroundColorAttributeName : placeholderGray,
                                                NSParagraphStyleAttributeName : paragraphStyle};
        
        if ([self respondsToSelector:@selector(tintColor)]) {
            // Inset the placeholder by the same 5px on both sides so that it works in right-to-left languages too
            CGRect placeholderFrame = CGRectMake(5.f, 10.f, self.frame.size.width - 10.f, self.frame.size.height - 20.f);
            [self.placeholder drawInRect:placeholderFrame
                      withAttributes:placeholderAttributes];

        } else {
            CGRect placeholderFrame = CGRectMake(8.f, 8.f, self.frame.size.width - 10.f, self.frame.size.height - 20.f);
            NSAttributedString *attributedPlaceholder = [[NSAttributedString alloc] initWithString:self.placeholder
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
    // Add it to the superview so that the floating label does not
    // scroll with the text view contents
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
                self.frame = self.offsetTextViewFrame;
            } else {
                self.floatingLabel.frame = self.offsetFloatingLabelFrame;
            }
        } completion:nil];
    } else {
        self.floatingLabel.alpha = 1.f;
        if (self.animationDirection == RPFloatingPlaceholderAnimateDownward) {
            self.frame = self.offsetTextViewFrame;
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
            self.frame = self.originalTextViewFrame;
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
    
    self.originalFloatingLabelFrame = CGRectMake(self.originalTextViewFrame.origin.x + 5.f, self.originalTextViewFrame.origin.y,
                                                 self.originalTextViewFrame.size.width - 10.f, self.floatingLabel.frame.size.height);
    self.floatingLabel.frame = self.originalFloatingLabelFrame;
    
    self.offsetFloatingLabelFrame = CGRectMake(self.originalFloatingLabelFrame.origin.x, self.originalFloatingLabelFrame.origin.y - offset,
                                           self.originalFloatingLabelFrame.size.width, self.originalFloatingLabelFrame.size.height);
    
    self.offsetTextViewFrame = CGRectMake(self.originalTextViewFrame.origin.x, self.originalTextViewFrame.origin.y + offset,
                                      self.originalTextViewFrame.size.width, self.originalTextViewFrame.size.height - offset);
}

- (void)animateFloatingLabelColorChangeWithAnimationBlock:(void (^)(void))animationBlock
{
    UIViewAnimationOptions options = UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionTransitionCrossDissolve;
    [UIView transitionWithView:self.floatingLabel duration:0.25 options:options animations:^{
        animationBlock();
    } completion:nil];
}

#pragma mark - Text View Observers

- (void)textViewDidBeginEditing:(NSNotification *)notification
{
    __weak __typeof(self) weakSelf = self;
    [self animateFloatingLabelColorChangeWithAnimationBlock:^{
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        self.floatingLabel.textColor = strongSelf.floatingLabelActiveTextColor;
    }];
}

- (void)textViewDidEndEditing:(NSNotification *)notification
{
    __weak __typeof(self) weakSelf = self;
    [self animateFloatingLabelColorChangeWithAnimationBlock:^{
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        self.floatingLabel.textColor = strongSelf.floatingLabelInactiveTextColor;
    }];
}

- (void)textViewTextDidChange:(NSNotification *)notification
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
