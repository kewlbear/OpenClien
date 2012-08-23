//
//  WebViewController.h
//  Clien
//
//  Created by 안창범 on 12. 8. 22..
//  Copyright (c) 2012년 안창범. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WebViewController : UIViewController

@property (weak, nonatomic) UIWebView* webView;
@property (copy, nonatomic) NSString* href;

@end
