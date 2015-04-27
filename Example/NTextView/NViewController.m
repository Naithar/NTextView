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

@end

@implementation NViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.

    NHTextView *textView = [[NHTextView alloc] initWithFrame:CGRectMake(0, 50, 300, 10)];
    textView.backgroundColor = [UIColor lightGrayColor];
    textView.font = [UIFont systemFontOfSize:12];
    textView.placeholder = @"Placeholder";
    textView.findLinks = YES;
    textView.findHashtags = YES;
    textView.findMentions = YES;
    textView.isGrowingTextView = YES;
    textView.numberOfLines = 3;
    
    [self.view addSubview:textView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
