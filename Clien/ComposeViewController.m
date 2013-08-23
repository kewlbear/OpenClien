//
//  ComposeViewController.m
//  Clien
//
//  Created by 안창범 on 13. 7. 16..
//  Copyright (c) 2013년 안창범. All rights reserved.
//

#import "ComposeViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "AFHTTPClient.h"
#import "NSScanner+Skip.h"
#import "ComposeTextCell.h"

@interface ComposeViewController ()

@end

@implementation ComposeViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismiss)];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"보내기" style:UIBarButtonItemStylePlain target:self action:@selector(submit:)];
    }
    return self;
}

- (void)submit:(id)sender {
    AFHTTPClient* httpClient = [AFHTTPClient clientWithBaseURL:_url];
    NSMutableDictionary* parameters = [@{//@"wr_name": @"test",
                                       @"w": @"c"}
                                       mutableCopy];
    NSArray* array = [_url.baseURL.query componentsSeparatedByString:@"&"];
    for (NSString* parameter in array) {
        NSArray* nameValue = [parameter componentsSeparatedByString:@"="];
        NSLog(@"%@", nameValue);
        parameters[nameValue[0]] = nameValue[1];
    }
    parameters[@"wr_content"] = _textCell.textView.text;
    [httpClient postPath:@"" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        // fixme
        NSString* response = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        NSLog(@"%@", response);
        // fixme merge message handling
        NSScanner* scanner = [NSScanner scannerWithString:response];
        if ([scanner skip:@"alert('"]) {
            NSString* message;
            [scanner scanUpToString:@"'" intoString:&message];
            message = [message stringByReplacingOccurrencesOfString:@"\\n" withString:@" "];
            UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:nil message:message delegate:nil cancelButtonTitle:nil otherButtonTitles:@"확인", nil];
            [alertView show];
        } else {
            if (_successBlock) {
                _successBlock();
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@", error);
        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:nil message:error.localizedDescription delegate:nil cancelButtonTitle:nil otherButtonTitles:@"확인", nil];
        [alertView show];
    }];
}

- (void)dismiss {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationController.view.superview.layer.cornerRadius = 5;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        if (YES || animated)
        {
            CATransition *slide = [CATransition animation];
            
            slide.type = kCATransitionPush;
            slide.subtype = kCATransitionFromTop;
            slide.duration = 0.4;
            slide.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
            
            slide.removedOnCompletion = YES;
            
            [self.navigationController.view.superview.layer addAnimation:slide forKey:@"slidein"];
        }
    }
}

//- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
//    return indexPath.row == 0 ? 100 : 44; // fixme
//}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
