//
//  NTextView.m
//  Pods
//
//  Created by Naithar on 23.04.15.
//
//

#import "NHTextView.h"

@interface NHTextView ()

@property (nonatomic, strong) UILabel *placeholderLabel;
@property (nonatomic, strong) id textChangeObserver;


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
}

- (void)textChanged {
    self.placeholderLabel.hidden = (self.text != nil
                                    && [self.text length] > 0);
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