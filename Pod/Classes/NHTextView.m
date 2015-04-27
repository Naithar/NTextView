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

NSString *const kNHTextViewLinkAttributesSetting = @"NHTextViewLinkAttributes";
NSString *const kNHTextViewHashtagAttributesSetting = @"NHTextViewHashtagAttributes";
NSString *const kNHTextViewMentionAttributesSetting = @"NHTextViewMentionAttributes";

NSString *const kNHTextViewHashtagPattern = @"(#\\w+)";
NSString *const kNHTextViewMentionPattern = @"(\\A|\\W)(@\\w+)";

@interface NHTextView ()

@property (nonatomic, strong) UILabel *placeholderLabel;
@property (nonatomic, strong) id textChangeObserver;
@property (nonatomic, strong) UIColor *textViewColor;

@property (nonatomic, strong) NSLayoutConstraint *heightConstraint;
@end

@implementation NHTextView

- (instancetype)init {
    self = [super init];

    if (self) {
        [self commonInit];
    }
    return self;
}

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

- (void)commonInit {
    self.layoutManager.allowsNonContiguousLayout = NO;
    self.spellCheckingType = UITextSpellCheckingTypeNo;
    [self setTranslatesAutoresizingMaskIntoConstraints:NO];

    _findLinks = NO;
    _findMentions = NO;
    _findHashtags = NO;
    _isGrowingTextView = NO;
    _useHeightConstraint = NO;
    _numberOfLines = -1;

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

    [self addSubview:self.placeholderLabel];
    [self sendSubviewToBack:self.placeholderLabel];

    self.placeholderLabel.hidden = (self.text != nil
                                    && [self.text length] > 0);

    __weak __typeof(self) weakSelf = self;
    self.textChangeObserver = [[NSNotificationCenter defaultCenter]
                               addObserverForName:UITextViewTextDidChangeNotification
                               object:nil
                               queue:nil usingBlock:^(NSNotification *note) {
                                   __strong __typeof(weakSelf) strongSelf = weakSelf;
                                   [strongSelf textChanged];
                               }];

    _linkAttributes = ifNSNull([NHTextView defaultSettings][kNHTextViewLinkAttributesSetting], nil);
    _hashtagAttributes = ifNSNull([NHTextView defaultSettings][kNHTextViewHashtagAttributesSetting], nil);
    _mentionAttributes = ifNSNull([NHTextView defaultSettings][kNHTextViewMentionAttributesSetting], nil);

    [self checkForGrowing];
}

- (void)textChanged {
    self.placeholderLabel.hidden = (self.text != nil
                                    && [self.text length] > 0);

    [self findLinksHashtagsAndMentions];
}

- (void)findLinksHashtagsAndMentions {
    if (!self.findLinks
        && !self.findHashtags
        && !self.findMentions) {
        return;
    }

    static NSString *previousText = nil;

    if ([self.text isEqualToString:previousText]) {
        return;
    }

    NSRange selectedRange = self.selectedRange;

    NSMutableAttributedString *tempAttributedString;

    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    paragraphStyle.alignment = self.textAlignment;
//    paragraphStyle.minimumLineHeight = self.font.lineHeight + 3;
//    paragraphStyle.maximumLineHeight = self.font.lineHeight + 3;

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


    [self checkForGrowing];

    self.selectedRange = selectedRange;
    previousText = self.text;
}

- (void)checkForGrowing {
    if (!self.isGrowingTextView) {
        return;
    }

    UIEdgeInsets inset = self.contentInset;
    if ([super respondsToSelector:@selector(textContainerInset)]) {
        inset = self.textContainerInset;
    }

    CGFloat currentWidth = self.bounds.size.width - inset.left - inset.right;
    CGFloat currentHeight = round([self.attributedText
                             boundingRectWithSize:CGSizeMake(currentWidth, CGFLOAT_MAX)
                             options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading
                             context:nil].size.height);

    NSInteger currentNumberOfLines = round(currentHeight / ((self.font ?: [UIFont systemFontOfSize:12]).lineHeight));

    if (currentNumberOfLines > self.numberOfLines
        && self.numberOfLines != -1) {
        return;
    }

    CGFloat newHeight = round(MAX((self.font ?: [UIFont systemFontOfSize:12]).lineHeight, currentHeight) + inset.top + inset.bottom);

//    if (self.useHeightConstraint) {
//
//    }
//    else {
        self.heightConstraint.constant = newHeight;
        CGRect currentBounds = self.frame;
        currentBounds.size.height = newHeight;
        self.frame = currentBounds;
//    }
//    [self setNeedsLayout];
    [self layoutIfNeeded];
    
    self.contentOffset = CGPointZero;
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

- (void)setIsGrowingTextView:(BOOL)isGrowingTextView {
    [self willChangeValueForKey:@"isGrowingTextView"];
    _isGrowingTextView = isGrowingTextView;

    UIEdgeInsets inset = self.contentInset;
    if ([super respondsToSelector:@selector(textContainerInset)]) {
        inset = self.textContainerInset;
    }

    [self checkForGrowing];

    [self setNeedsLayout];
    [self layoutIfNeeded];

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
                                          regularExpressionWithPattern:kNHTextViewHashtagPattern
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
                                          regularExpressionWithPattern:kNHTextViewMentionPattern
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
    [super setFont:font];
    self.placeholderLabel.font = font;
    [self.placeholderLabel sizeToFit];
}

- (void)setTextColor:(UIColor *)textColor {
    [super setTextColor:textColor];
    self.textViewColor = textColor;
}

- (UIColor *)textColor {
    return self.textViewColor;
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

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self.textChangeObserver];
}

@end


//RACObserve($0, "bounds").subscribeNext { [weak weakTextView = $0, weak weakSelf = self] data in
//    if weakSelf?.textViewHeight?.constant < weakSelf?.maxTextViewHeight {
//        weakTextView?.contentOffset.y = 0
//    }
//    return
//}
//
//RACObserve($0, "text").distinctUntilChanged().subscribeNext { [weak weakTextView = $0, weak weakSelf = self] data in
//
//    let range = weakTextView?.selectedRange
//
//    weakTextView?.font = weakSelf?.font ?? weakSelf?.defaultTextViewFont
//    weakTextView?.textColor = weakSelf?.editedTextColor ?? weakSelf?.defaultTextColor
//
//    if let text = data as? String {
//        weakSelf?.didChangeText?(weakSelf, weakTextView, text)
//        weakSelf?.recalculateTextViewHeight(weakTextView, text: text)
//    }
//
//    if let textRange = range {
//        weakTextView?.selectedRange = textRange
//    }
//    return
//    }
//
//    $0.rac_textSignal()/*.distinctUntilChanged()*/.subscribeNext { [weak weakTextView = $0, weak weakSelf = self] data in
//        if let text = data as? String {
//            let range = weakTextView?.selectedRange
//
//            weakTextView?.text = text
//
//            if let textRange = range {
//                weakTextView?.selectedRange = textRange
//            }
//
//            if let attributed = weakTextView?.attributedText {
//                var mutableAttributed = NSMutableAttributedString(attributedString: attributed)
//
//                mutableAttributed.removeAttribute(NSLinkAttributeName, range: NSRange(0..<mutableAttributed.length))
//
//                weakTextView?.attributedText = mutableAttributed
//            }
//
//
//        }
//        return
//    }


//func recalculateTextViewHeight(textView: UITextView?, text: String!) {
//    var textHeight = text.utf16Count > 0
//    ? STBHelper.getStringRectFromAttributedText(textView?.attributedText, andMaxWidth: (textView?.bounds.width ?? self.textViewWidthOffset) - self.textViewWidthOffset).height
//    : STBHelper.getStringRectFromText(text,
//                                      andFont: textView?.font ?? defaultTextViewFont,
//                                      andMaxWidth: (textView?.bounds.width ?? self.textViewWidthOffset) - self.textViewWidthOffset,
//                                      andLineBreakMode: NSLineBreakMode.ByWordWrapping).height
//
//    let height = CGFloat(ceil(textHeight)) + self.textViewHeightOffset
//
//    let maxHeight = self.maxTextViewHeight
//
//    textView?.contentSize.height = height
//
//    if height <= maxHeight {
//        self.textViewHeight?.constant = CGFloat(height)
//    }
//    else {
//        self.textViewHeight?.constant = CGFloat(maxHeight)
//    }
//
//    UIView.animateWithDuration(
//                               0.15,
//                               delay: 0,
//                               options: UIViewAnimationOptions.BeginFromCurrentState | UIViewAnimationOptions.CurveLinear,
//                               animations: { [weak weakSelf = self] in
//                                   weakSelf?.parentView?.setNeedsUpdateConstraints()
//                                   weakSelf?.parentView?.layoutIfNeeded()
//                               }, completion: nil)
//}