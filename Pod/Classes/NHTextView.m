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
                              NSForegroundColorAttributeName : [UIColor colorWithRed:0 green:0.5 blue:1 alpha:1],
                              NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle)
                              },
                      kNHTextViewHashtagAttributesSetting : @{
                              NSForegroundColorAttributeName : [UIColor colorWithRed:0 green:0.5 blue:1 alpha:1],
                              },
                      kNHTextViewMentionAttributesSetting : @{
                              NSForegroundColorAttributeName : [UIColor colorWithRed:1 green:0.25 blue:0 alpha:1],
                              NSFontAttributeName : [UIFont boldSystemFontOfSize:12],
                              }
                      } mutableCopy];
    });

    return settings;
}

- (void)commonInit {
    self.layoutManager.allowsNonContiguousLayout = NO;

    UIEdgeInsets inset = self.contentInset;
    if ([super respondsToSelector:@selector(textContainerInset)]) {
        inset = self.textContainerInset;
    }

    self.placeholderLabel = [[UILabel alloc] initWithFrame:CGRectMake(inset.left + 4.5,
                                                                      inset.top,
                                                                      self.bounds.size.width - inset.left - inset.right,
                                                                      0)];
    self.placeholderLabel.backgroundColor = [UIColor clearColor];
    self.placeholderLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    self.placeholderLabel.numberOfLines = 1;
    self.placeholderLabel.font = self.font ?: [UIFont systemFontOfSize:12];
    self.placeholderLabel.textColor = [UIColor colorWithRed:0 green:0 blue:0.098 alpha:0.22];
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
    self.selectedRange = selectedRange;
    previousText = self.text;

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