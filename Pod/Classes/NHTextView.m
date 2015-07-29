//
//  NTextView.m
//  Pods
//
//  Created by Naithar on 23.04.15.
//
//

#import "NHTextView.h"

#define ifNSNull(x, y) \
([x isKindOfClass:[NSNull class]]) ? y : (x ?: y)

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v) \
([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

NSString *const kNHTextViewLinkAttributesSetting = @"NHTextViewLinkAttributes";
NSString *const kNHTextViewHashtagAttributesSetting = @"NHTextViewHashtagAttributes";
NSString *const kNHTextViewMentionAttributesSetting = @"NHTextViewMentionAttributes";
NSString *const kNHTextViewMentionRegexpSetting = @"NHTextViewMentionRegexp";
NSString *const kNHTextViewHashtagRegexpSetting = @"NHtextViewHashtagRegexp";

const CGFloat kNHTextViewDefaultCaretSize = -1;
const NSInteger kNHTextViewDefaultTextLength = -1;
const NSInteger kNHTextViewDefaultNumberOfLines = -1;

NSString *const kNHTextViewHashtagPattern = @"(#\\w+)";
NSString *const kNHTextViewMentionPattern = @"(\\A|\\W)(@\\w+)";

@interface NHTextView ()

@property (nonatomic, strong) UILabel *placeholderLabel;
@property (nonatomic, strong) id textChangeObserver;
@property (nonatomic, strong) UIColor *textViewColor;
@property (nonatomic, strong) UIFont *textViewFont;

@property (nonatomic, strong) NSLayoutConstraint *heightConstraint;
@end

@implementation NHTextView

//- (instancetype)init {
//    self = [super init];
//
//    if (self) {
//        [self commonInit];
//    }
//    return self;
//}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];

    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];

    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
                textContainer:(NSTextContainer *)textContainer {
    self = [super initWithFrame:frame
                  textContainer:textContainer];

    if (self) {
        [self commonInit];
    }
    return self;
}

+ (NSMutableDictionary*)defaultSettings
{
    static dispatch_once_t token;
    __strong static NSMutableDictionary* settings = nil;
    dispatch_once(&token, ^{
        settings = [@{
                      kNHTextViewLinkAttributesSetting : @{
                              NSForegroundColorAttributeName : [UIColor colorWithRed:0
                                                                               green:0.5
                                                                                blue:1
                                                                               alpha:1],
                              NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle)
                              },
                      kNHTextViewHashtagAttributesSetting : @{
                              NSForegroundColorAttributeName : [UIColor colorWithRed:0
                                                                               green:0.5
                                                                                blue:1
                                                                               alpha:1],
                              },
                      kNHTextViewMentionAttributesSetting : @{
                              NSForegroundColorAttributeName : [UIColor colorWithRed:1
                                                                               green:0.25
                                                                                blue:0
                                                                               alpha:1],
                              NSFontAttributeName : [UIFont boldSystemFontOfSize:12],
                              }
                      } mutableCopy];
    });

    return settings;
}

- (CGSize)intrinsicContentSize {
    return CGSizeMake(UIViewNoIntrinsicMetric, self.heightConstraint.constant);
}

- (void)commonInit {
    self.layoutManager.allowsNonContiguousLayout = NO;
    self.spellCheckingType = UITextSpellCheckingTypeYes;
    [self setTranslatesAutoresizingMaskIntoConstraints:NO];

    _caretRect = CGRectNull;
    _caretSize = CGSizeMake(kNHTextViewDefaultCaretSize, kNHTextViewDefaultCaretSize);
    _caretOffset = CGPointZero;
    _findLinks = NO;
    _findMentions = NO;
    _findHashtags = NO;
    _isGrowingTextView = NO;
    _useHeightConstraint = NO;
    _numberOfLines = kNHTextViewDefaultNumberOfLines;
    _maxLenght = kNHTextViewDefaultTextLength;
    _gotMaxLength = NO;

    self.heightConstraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeHeight multiplier:0 constant:40];

    UIEdgeInsets inset = self.contentInset;
    if ([super respondsToSelector:@selector(textContainerInset)]) {
        inset = self.textContainerInset;
    }

    self.placeholderLabel = [[UILabel alloc] initWithFrame:CGRectMake(inset.left + 4.5,
                                                                      inset.top,
                                                                      (self.bounds.size.width
                                                                       - inset.left
                                                                       - inset.right),
                                                                      0)];
    self.placeholderLabel.backgroundColor = [UIColor clearColor];
    self.placeholderLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    self.placeholderLabel.numberOfLines = 1;
    self.placeholderLabel.font = self.font ?: [UIFont systemFontOfSize:12];
    self.placeholderLabel.textColor = [UIColor colorWithRed:0
                                                      green:0
                                                       blue:0.098
                                                      alpha:0.22];
    self.placeholderLabel.text = self.placeholder;

    [self.placeholderLabel sizeToFit];
    [self addSubview:self.placeholderLabel];
    [self sendSubviewToBack:self.placeholderLabel];

    self.placeholderLabel.hidden = (self.text != nil
                                    && [self.text length] > 0);

    __weak __typeof(self) weakSelf = self;
    self.textChangeObserver = [[NSNotificationCenter defaultCenter]
                               addObserverForName:UITextViewTextDidChangeNotification
                               object:self
                               queue:nil usingBlock:^(NSNotification *note) {
                                   __strong __typeof(weakSelf) strongSelf = weakSelf;
                                   [strongSelf textChanged];
                               }];

    _linkAttributes = ifNSNull([NHTextView defaultSettings][kNHTextViewLinkAttributesSetting], nil);
    _hashtagAttributes = ifNSNull([NHTextView defaultSettings][kNHTextViewHashtagAttributesSetting], nil);
    _mentionAttributes = ifNSNull([NHTextView defaultSettings][kNHTextViewMentionAttributesSetting], nil);

    _mentionRegexp = ifNSNull([NHTextView defaultSettings][kNHTextViewMentionRegexpSetting], nil);
    _hashtagRegexp = ifNSNull([NHTextView defaultSettings][kNHTextViewHashtagRegexpSetting], nil);
    
    [self checkForGrowing];
}

- (void)textChanged {

    NSRange selectedRange = self.selectedRange;

    self.placeholderLabel.hidden = (self.text != nil
                                    && [self.text length] > 0);

    [self findLinksHashtagsAndMentions];

    [self checkForGrowingAnimated:YES];

    self.selectedRange = selectedRange;

    __weak __typeof(self) weakSelf = self;
    if ([weakSelf.nhTextViewDelegate respondsToSelector:@selector(textView:didChangeText:)]) {
        [weakSelf.nhTextViewDelegate textView:weakSelf didChangeText:self.text];
    }

    if ([weakSelf.nhTextViewDelegate respondsToSelector:@selector(textView:didChangeAttributedText:)]) {
        [weakSelf.nhTextViewDelegate textView:weakSelf didChangeAttributedText:self.attributedText];
    }
}

- (void)findLinksHashtagsAndMentions {
    if (!self.findLinks
        && !self.findHashtags
        && !self.findMentions) {
        return;
    }

    if (self.maxLenght != kNHTextViewDefaultTextLength
        && [self.text length] > self.maxLenght) {
        __weak __typeof(self) weakSelf = self;
        if ([weakSelf.nhTextViewDelegate respondsToSelector:@selector(textViewShouldStopOnMaxLength:)]) {
            if ([weakSelf.nhTextViewDelegate textViewShouldStopOnMaxLength:weakSelf]) {
                self.text = [self.text substringToIndex:self.maxLenght];
                return;
            }
        }

        self.gotMaxLength = YES;
    }
    else {
        self.gotMaxLength = NO;
    }

    NSMutableAttributedString *tempAttributedString;

    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    paragraphStyle.alignment = self.textAlignment;

    tempAttributedString = [[NSMutableAttributedString alloc]
                            initWithString:self.text ?: @""
                            attributes:@{
                                         NSFontAttributeName : self.font ?: [UIFont systemFontOfSize:12],
                                         NSForegroundColorAttributeName : self.textColor ?: [UIColor blackColor],
                                         NSParagraphStyleAttributeName : paragraphStyle
                                         }];
    if (self.findLinks) {
        [self findLinksInAttributedString:tempAttributedString
                           withAttributes:self.linkAttributes];
    }

    if (self.findHashtags) {
        [self findHashtagsInAttributedString:tempAttributedString
                              withAttributes:self.hashtagAttributes];
    }

    if (self.findMentions) {
        [self findMentionsInAttributedString:tempAttributedString
                              withAttributes:self.mentionAttributes];
    }

    self.attributedText = tempAttributedString;
}

- (void)checkForGrowing {
    [self checkForGrowingAnimated:NO];
}

- (BOOL)shouldAddHeight {
    NSInteger stringLength = [[self.attributedText string] length];
    if (!SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")
        && stringLength > 0) {
        if ([[[self.attributedText string] substringFromIndex:stringLength - 1] isEqualToString:@"\n"]) {
            return YES;
        }
    }

    return NO;
}

- (void)checkForGrowingAnimated:(BOOL)animated {
    if (!self.isGrowingTextView) {
        return;
    }

    UIEdgeInsets inset = self.contentInset;
    if ([super respondsToSelector:@selector(textContainerInset)]) {
        inset = self.textContainerInset;
    }

    CGFloat currentWidth = self.bounds.size.width - inset.left - inset.right - 10;
    CGFloat currentHeight = round([self.attributedText
                                   boundingRectWithSize:CGSizeMake(currentWidth, CGFLOAT_MAX)
                                   options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading
                                   context:nil].size.height);

    if ([self shouldAddHeight]) {
        currentHeight += ((self.font ?: [UIFont systemFontOfSize:12]).lineHeight);
    }

    NSInteger currentNumberOfLines = round(currentHeight / ((self.font ?: [UIFont systemFontOfSize:12]).lineHeight));
    CGFloat maxHeight = round(self.numberOfLines * (self.font ?: [UIFont systemFontOfSize:12]).lineHeight) + inset.top + inset.bottom;

    if (currentNumberOfLines > self.numberOfLines
        && self.heightConstraint.constant == maxHeight
        && self.numberOfLines != kNHTextViewDefaultNumberOfLines) {
        return;
    }

    CGFloat newHeight = MIN(maxHeight,
                            round(MAX((self.font ?: [UIFont systemFontOfSize:12]).lineHeight,
                                      currentHeight)
                                  + inset.top + inset.bottom));

    [UIView animateWithDuration: animated ? 0.2 : 0 animations:^{
        self.heightConstraint.constant = MAX(0, newHeight);
        CGRect currentBounds = self.frame;
        currentBounds.size.height = MAX(0, newHeight);
        self.frame = currentBounds;

        if (!self.useHeightConstraint) {
            [self invalidateIntrinsicContentSize];
        }

        [self.superview layoutIfNeeded];
    }];

    self.contentOffset = CGPointZero;

    __weak __typeof(self) weakSelf = self;
    if ([weakSelf.nhTextViewDelegate respondsToSelector:@selector(textView:didChangeHeight:)]) {
        [weakSelf.nhTextViewDelegate textView:weakSelf didChangeHeight:newHeight];
    }
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
}

- (void)setBounds:(CGRect)bounds {
    [super setBounds:bounds];

    UIEdgeInsets inset = self.contentInset;
    if ([super respondsToSelector:@selector(textContainerInset)]) {
        inset = self.textContainerInset;
    }

    NSInteger currentNumberOfLines = round((self.contentSize.height - inset.top - inset.bottom) / ((self.font ?: [UIFont systemFontOfSize:12]).lineHeight));
    if (currentNumberOfLines <= self.numberOfLines) {
        self.contentOffset = CGPointZero;
    }

}

- (void)setContentSize:(CGSize)contentSize {
    CGSize previousSize = self.contentSize;
    [super setContentSize:contentSize];

    if (previousSize.width != self.contentSize.width) {
        [self checkForGrowingAnimated:YES];
    }
}

- (void)setContentOffset:(CGPoint)contentOffset {
    if (CGPointEqualToPoint(contentOffset, self.contentOffset)) {

        UIEdgeInsets inset = self.contentInset;
        if ([super respondsToSelector:@selector(textContainerInset)]) {
            inset = self.textContainerInset;
        }

        NSInteger currentNumberOfLines = round((self.contentSize.height - inset.top - inset.bottom) / ((self.font ?: [UIFont systemFontOfSize:12]).lineHeight));
        if (currentNumberOfLines > self.numberOfLines
            && [self shouldAddHeight]) {
            CGPoint newOffset = CGPointMake(self.contentOffset.x, (currentNumberOfLines - self.numberOfLines) * ((self.font ?: [UIFont systemFontOfSize:12]).lineHeight));
            self.contentOffset = newOffset;
        }

        return;
    }

    [super setContentOffset:contentOffset];;
}

- (void)setIsGrowingTextView:(BOOL)isGrowingTextView {
    [self willChangeValueForKey:@"isGrowingTextView"];
    _isGrowingTextView = isGrowingTextView;

    [self checkForGrowing];

    [self.superview setNeedsLayout];
    [self.superview layoutIfNeeded];

    [self didChangeValueForKey:@"isGrowingTextView"];
}

- (void)findLinksInAttributedString:(NSMutableAttributedString*)string
                     withAttributes:(NSDictionary*)attributes {
    if (!string) {
        return;
    }

    NSRange textRange = NSMakeRange(0, [string length]);

    NSDataDetector *dataDetector = [NSDataDetector
                                    dataDetectorWithTypes:NSTextCheckingTypeLink
                                    error:nil];

    [dataDetector enumerateMatchesInString:[string string]
                                   options:0
                                     range:textRange
                                usingBlock:^(NSTextCheckingResult *result,
                                             NSMatchingFlags flags,
                                             BOOL *stop) {
                                    NSRange linkRange = [result rangeAtIndex:0];

                                    [string addAttributes:attributes ?: @{}
                                                    range:linkRange];
                                }];
}

- (void)findHashtagsInAttributedString:(NSMutableAttributedString*)string
                        withAttributes:(NSDictionary*)attributes {
    if (!string) {
        return;
    }

    NSRange textRange = NSMakeRange(0, [string length]);

    NSRegularExpression *hashtagRegExp = [NSRegularExpression
                                          regularExpressionWithPattern:self.hashtagRegexp ?: kNHTextViewHashtagPattern
                                          options:0
                                          error:nil];



    [hashtagRegExp enumerateMatchesInString:[string string]
                                    options:0
                                      range:textRange
                                 usingBlock:^(NSTextCheckingResult *result,
                                              NSMatchingFlags flags,
                                              BOOL *stop) {
                                     NSRange hashtagRange = [result rangeAtIndex:0];

                                     [string addAttributes:attributes ?: @{}
                                                     range:hashtagRange];
                                 }];
}

- (void)findMentionsInAttributedString:(NSMutableAttributedString*)string
                        withAttributes:(NSDictionary*)attributes {
    if (!string) {
        return;
    }

    NSRange textRange = NSMakeRange(0, [string length]);

    NSRegularExpression *mentionRegExp = [NSRegularExpression
                                          regularExpressionWithPattern:self.mentionRegexp ?: kNHTextViewMentionPattern
                                          options:0
                                          error:nil];

    [mentionRegExp enumerateMatchesInString:[string string]
                                    options:0
                                      range:textRange
                                 usingBlock:^(NSTextCheckingResult *result,
                                              NSMatchingFlags flags,
                                              BOOL *stop) {
                                     NSRange mentionRange = [result rangeAtIndex:0];

                                     [string addAttributes:attributes ?: @{}
                                                     range:mentionRange];
                                 }];
}

- (void)setContentInset:(UIEdgeInsets)contentInset {
    [super setContentInset:contentInset];

    if (![super respondsToSelector:@selector(textContainerInset)]) {
        self.placeholderLabel.frame = CGRectMake(contentInset.left + 4.5,
                                                 contentInset.top,
                                                 (self.bounds.size.width
                                                  - contentInset.left
                                                  - contentInset.right),
                                                 0);
        [self.placeholderLabel sizeToFit];
        [self sendSubviewToBack:self.placeholderLabel];

        [self checkForGrowingAnimated:YES];
    }
}

- (void)setTextContainerInset:(UIEdgeInsets)textContainerInset {
    if ([super respondsToSelector:@selector(textContainerInset)]) {
        [super setTextContainerInset:textContainerInset];

        self.placeholderLabel.frame = CGRectMake(textContainerInset.left + 4.5,
                                                 textContainerInset.top,
                                                 (self.bounds.size.width
                                                  - textContainerInset.left
                                                  - textContainerInset.right),
                                                 0);
        [self.placeholderLabel sizeToFit];
        [self sendSubviewToBack:self.placeholderLabel];

        [self checkForGrowingAnimated:YES];
    }

}

- (void)setUseHeightConstraint:(BOOL)useHeightConstraint {
    [self willChangeValueForKey:@"useHeightConstraint"];
    _useHeightConstraint = useHeightConstraint;
    [self removeConstraint:self.heightConstraint];

    if (useHeightConstraint) {
        [self addConstraint:self.heightConstraint];
    }
    [self didChangeValueForKey:@"useHeightConstraint"];
}

- (void)setText:(NSString *)text {
    [super setText:text];
    [self textChanged];
}

- (void)setFont:(UIFont *)font {
    self.textViewFont = font;
    self.placeholderLabel.font = font;
    [self.placeholderLabel sizeToFit];
    [super setFont:font];
}

- (UIFont *)font {
    return self.textViewFont ?: [UIFont systemFontOfSize:12];
}

- (void)setTextColor:(UIColor *)textColor {
    [self willChangeValueForKey:@"textColor"];
    self.textViewColor = textColor;
    [self didChangeValueForKey:@"textColor"];
}

- (UIColor *)textColor {
    return self.textViewColor ?: [UIColor blackColor];
}

- (void)setGotMaxLength:(BOOL)gotMaxLength {
    [self willChangeValueForKey:@"gotMaxLenght"];
    _gotMaxLength = gotMaxLength;
    [self didChangeValueForKey:@"gotMaxLength"];
}

- (void)setPlaceholder:(NSString *)placeholder {
    [self willChangeValueForKey:@"placeholder"];
    self.placeholderLabel.text = placeholder;
    [self.placeholderLabel sizeToFit];
    [self sendSubviewToBack:self.placeholderLabel];
    [self didChangeValueForKey:@"placeholder"];
}

- (void)setPlaceholderFont:(UIFont *)placeholderFont {
    [self willChangeValueForKey:@"placeholderFont"];
    self.placeholderLabel.font = placeholderFont ?: self.font ?: [UIFont systemFontOfSize:12];
    [self.placeholderLabel sizeToFit];
    [self sendSubviewToBack:self.placeholderLabel];
    [self didChangeValueForKey:@"placeholderFont"];
}

- (void)setPlaceholderColor:(UIColor *)placeholderColor {
    [self willChangeValueForKey:@"placeholderColor"];
    self.placeholderLabel.textColor = placeholderColor ?: [UIColor colorWithRed:0
                                                                          green:0
                                                                           blue:0.098
                                                                          alpha:0.22];;
    [self.placeholderLabel sizeToFit];
    [self sendSubviewToBack:self.placeholderLabel];
    [self didChangeValueForKey:@"placeholderColor"];
}

- (CGRect)caretRectForPosition:(UITextPosition *)position {
    if (CGRectIsNull(self.caretRect)) {
        CGRect resultCaretRect = [super caretRectForPosition:position];

        if (self.caretSize.width != kNHTextViewDefaultCaretSize) {
            resultCaretRect.size.width = self.caretSize.width;
        }

        if (self.caretSize.height != kNHTextViewDefaultCaretSize) {
            resultCaretRect.size.height = self.caretSize.height;
        }
        
        resultCaretRect.origin.x += self.caretOffset.x;
        resultCaretRect.origin.y += self.caretOffset.y;
        
        return resultCaretRect;
    }
    
    return self.caretRect;
}

- (void)dealloc {
    self.nhTextViewDelegate = nil;
    self.delegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self.textChangeObserver];
}

@end
