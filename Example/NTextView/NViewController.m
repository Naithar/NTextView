//
//  NViewController.m
//  NTextView
//
//  Created by Naithar on 04/23/2015.
//  Copyright (c) 2014 Naithar. All rights reserved.
//

#import "NViewController.h"
#import <NHTextView.h>

@interface NViewController ()
@property (strong, nonatomic) IBOutlet NHTextView *nhTextView;

@end

@implementation NViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
//
    NHTextView *textView = [[NHTextView alloc] initWithFrame:CGRectMake(0, 50, 300, 50)];
    textView.backgroundColor = [UIColor lightGrayColor];
    textView.font = [UIFont systemFontOfSize:12];
    textView.placeholder = @"Placeholder";
    textView.findLinks = YES;
    textView.findHashtags = YES;
    textView.findMentions = YES;
    textView.isGrowingTextView = YES;
    textView.numberOfLines = 3;
//    textView.caretSize = CGSizeMake(5, 1);
//    textView.caretOffset = CGPointMake(10, 14);

    self.nhTextView.backgroundColor = [UIColor lightGrayColor];
    self.nhTextView.font = [UIFont systemFontOfSize:12];
    self.nhTextView.placeholder = @"Placeholder";
    self.nhTextView.findLinks = YES;
    self.nhTextView.findHashtags = YES;
    self.nhTextView.findMentions = YES;
    self.nhTextView.isGrowingTextView = YES;
    self.nhTextView.numberOfLines = 3;
    self.nhTextView.useHeightConstraint = YES;
    self.nhTextView.caretSize = CGSizeMake(5, 1);
    self.nhTextView.caretOffset = CGPointMake(10, 14);

    [self.view addSubview:textView];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        textView.textContainerInset = UIEdgeInsetsMake(0, 0, 0, 0);
    });
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
