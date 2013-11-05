//
//  UIViewController+URL.h
//  Clien
//
// Copyright 2013 Changbeom Ahn
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import <UIKit/UIKit.h>
#import <StoreKit/StoreKit.h>

typedef void (^LoginCompletionBlock)(NSString* message);
typedef void (^LoginAlertViewCompletionBlock)(BOOL canceled, NSString* message);

@protocol URLProvider <NSObject>

@optional

- (NSURL*)URL;

@end

@interface UIViewController (URL) <SKStoreProductViewControllerDelegate, URLProvider>

- (void)openURL:(NSURL*)url;

- (BOOL)webViewShouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType;

- (void)tryLoginWithID:(NSString*)memberID password:(NSString*)password completionBlock:(LoginCompletionBlock)block;

- (void)showLoginAlertViewWithMessage:(NSString*)message completionBlock:(LoginAlertViewCompletionBlock)block;

@end
