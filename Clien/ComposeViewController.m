//
//  ComposeViewController.m
//  Clien
//
//  Created by 안창범 on 13. 7. 16..
//  Copyright (c) 2013년 안창범. All rights reserved.
//

#import "ComposeViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface ComposeViewController ()

@end

@implementation ComposeViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismiss)];
    }
    return self;
}

- (void)dismiss {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _tableView.superview.layer.cornerRadius = 5;
    _navigationBar.items = @[self.navigationItem];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        if (animated)
        {
            CATransition *slide = [CATransition animation];
            
            slide.type = kCATransitionPush;
            slide.subtype = kCATransitionFromTop;
            slide.duration = 0.4;
            slide.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
            
            slide.removedOnCompletion = YES;
            
            [_tableView.superview.layer addAnimation:slide forKey:@"slidein"];
        }
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 4;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Text"];
        return cell;
    } else {
        UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Option"];
        cell.textLabel.text = [NSString stringWithFormat:@"Option %d", indexPath.row];
        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.row == 0 ? 100 : 44; // fixme
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
