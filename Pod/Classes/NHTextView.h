//
//  NTextView.h
//  Pods
//
//  Created by Naithar on 23.04.15.
//
//

#import <Foundation/Foundation.h>

extern NSString *const kNHTextViewLinkAttributesSetting;
extern NSString *const kNHTextViewHashtagAttributesSetting;
extern NSString *const kNHTextViewMentionAttributesSetting;

extern NSString *const kNHTextViewMentionRegexpSetting;
extern NSString *const kNHTextViewHashtagRegexpSetting;

extern const CGFloat kNHTextViewDefaultCaretSize;
extern const NSInteger kNHTextViewDefaultTextLength;
extern const NSInteger kNHTextViewDefaultNumberOfLines;

@class NHTextView;

@protocol NHTextViewDelegate <NSObject>

@optional
- (void)textView:(NHTextView*)textView didChangeHeight:(CGFloat)height;
- (BOOL)textViewShouldStopOnMaxLength:(NHTextView*)textView;
- (void)textView:(NHTextView *)textView didChangeText:(NSString*)text;
- (void)textView:(NHTextView *)textView didChangeAttributedText:(NSAttributedString*)attributed;

@end

@interface NHTextView : UITextView

@property (nonatomic, weak) id<NHTextViewDelegate> nhTextViewDelegate;

@property (nonatomic, assign) BOOL useHeightConstraint;

@property (nonatomic, assign) BOOL findLinks;
@property (nonatomic, assign) BOOL findHashtags;
@property (nonatomic, assign) BOOL findMentions;
@property (nonatomic, assign) BOOL isGrowingTextView;
@property (nonatomic, assign) NSInteger numberOfLines;

@property (nonatomic, assign) CGRect caretRect;
@property (nonatomic, assign) CGSize caretSize;
@property (nonatomic, assign) CGPoint caretOffset;

@property (nonatomic, copy) NSDictionary *linkAttributes;
@property (nonatomic, copy) NSDictionary *hashtagAttributes;
@property (nonatomic, copy) NSDictionary *mentionAttributes;

@property (nonatomic, copy) NSString *placeholder;
@property (nonatomic, strong) UIFont *placeholderFont;
@property (nonatomic, strong) UIColor *placeholderColor;

@property (nonatomic, assign) NSUInteger maxLenght;
@property (nonatomic, assign) BOOL gotMaxLength;

@property (nonatomic, copy) NSString *hashtagRegexp;
@property (nonatomic, copy) NSString *mentionRegexp;

+ (NSMutableDictionary*)defaultSettings;

@end
