//
//  UIViewController+URL.h
//  Clien
//
//  Created by 안창범 on 13. 8. 21..
//  Copyright (c) 2013년 안창범. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <StoreKit/StoreKit.h>

@interface UIViewController (URL) <SKStoreProductViewControllerDelegate>

- (void)openURL:(NSURL*)url;
- (BOOL)webViewShouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType;

@end
