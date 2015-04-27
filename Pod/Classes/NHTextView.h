//
//  NTextView.h
//  Pods
//
//  Created by Naithar on 23.04.15.
//
//

#import <Foundation/Foundation.h>

@interface NHTextView : UITextView

@property (nonatomic, assign) BOOL findLinks;
@property (nonatomic, assign) BOOL findHastags;
@property (nonatomic, assign) BOOL findMentions;

@property (nonatomic, copy) NSDictionary *linkAttributes;
@property (nonatomic, copy) NSDictionary *hastagAttributes;
@property (nonatomic, copy) NSDictionary *mentionAttributes;

@property (nonatomic, copy) NSString *placeholder;
@property (nonatomic, strong) UIFont *placeholderFont;
@property (nonatomic, strong) UIColor *placeholderColor;

@end
