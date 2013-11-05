//
//  UIViewController+URL.m
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

#import "UIViewController+URL.h"
#import "WebViewController.h"
#import "BoardViewController.h"
#import "ArticleViewController.h"
#import "UIViewController+Stack.h"
#import "AFHTTPClient.h"
#import "NSString+SubstringFromTo.h"
#import "Settings.h"
#import "ComposeViewController.h"

typedef void (^AlertViewClickBlock)(UIAlertView* alertView, NSInteger buttonIndex);
typedef void (^ActionSheetClickBlock)(UIActionSheet* actionSheet, NSInteger buttonIndex);

@interface Member : NSObject

@property (strong, nonatomic) NSString* ID;
@property (strong, nonatomic) NSString* name;

@end

@implementation Member

@end

@interface AlertViewDelegate : NSObject <UIAlertViewDelegate>

@property (strong, nonatomic) AlertViewClickBlock clickBlock;

+ (AlertViewDelegate*)sharedDelegate;

@end

@implementation AlertViewDelegate

+ (AlertViewDelegate*)sharedDelegate {
    static AlertViewDelegate* instance;
    if (!instance) {
        instance = [[AlertViewDelegate alloc] init];
    }
    return instance;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (_clickBlock) {
        _clickBlock(alertView, buttonIndex);
    }
}

@end

@interface ActionSheetDelegate : NSObject <UIActionSheetDelegate>

@property (strong, nonatomic) ActionSheetClickBlock clickBlock;

+ (ActionSheetDelegate*)sharedDelegate;

@end

@implementation ActionSheetDelegate

+ (ActionSheetDelegate*)sharedDelegate {
    static ActionSheetDelegate* instance;
    if (!instance) {
        instance = [[ActionSheetDelegate alloc] init];
    }
    return instance;
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (_clickBlock) {
        _clickBlock(actionSheet, buttonIndex);
    }
}

@end

@interface NSURL (Clien)

- (NSURL*)PCURL;
- (BOOL)isAppStoreURL;
- (BOOL)isNativeClienURL;

@end

@implementation NSURL (Clien)

- (NSURL*)PCURL {
    NSString* url = [self.absoluteString stringByReplacingOccurrencesOfString:@"m.clien.net/cs3/board" withString:@"www.clien.net/cs2/bbs/board.php"];
    return [NSURL URLWithString:url];
}

- (BOOL)isAppStoreURL {
    return [self.host isEqualToString:@"itunes.apple.com"] && [self.lastPathComponent hasPrefix:@"id"];
}

- (BOOL)isNativeClienURL {
    return [@[@"www.clien.net", @"clien.net", @"m.clien.net", @"clien.career.co.kr"] containsObject:self.host] &&
    [self.lastPathComponent hasPrefix:@"board"] &&
    [self.query rangeOfString:@"wr_id="].location != NSNotFound;
}

@end

@interface RedirectHandler : NSObject <NSURLConnectionDataDelegate> {
    NSMutableData* _data;
}

@property (nonatomic) BOOL done;
@property (readonly, nonatomic) NSData* data;
@property (readonly, nonatomic) NSURL* URL;

@end

@implementation RedirectHandler

- (NSURLRequest*)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response {
    NSLog(@"%s: response=%@", __func__, response);
    return request;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    NSLog(@"%s", __func__);
    _done = YES;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSLog(@"%s: %@", __func__, error);
    _done = YES;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response {
    NSLog(@"%s", __func__);
    if (response.expectedContentLength < 256 || [response.URL.absoluteString rangeOfString:@".clien.net/cs2/bbs/link.php?"].length) { // fixme
        _data = [NSMutableData data];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    // fixme stop loading?
    NSLog(@"%s", __func__);
    [_data appendData:data];
}

- (NSURL*)URL {
    NSString* string = [[NSString alloc] initWithData:_data encoding:NSUTF8StringEncoding];
    NSLog(@"%s: %@", __func__, string);
    string = [string substringFrom:@"location.replace('" to:@"'"];
    return [NSURL URLWithString:[string stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
}

@end

@implementation UIViewController (URL)

- (void)openURL:(NSURL *)url {
    NSURLRequest* request = [NSURLRequest requestWithURL:url];
    url = [self processRedirects:request];
    if ([self webViewShouldStartLoadWithURL:url]) {
        [self openWebViewWithURL:url];
    }
}

- (void)openWebViewWithURL:(NSURL*)url {
    NSLog(@"opening web view");
    WebViewController* wvc = [[WebViewController alloc] init];
    wvc.URL = url;
    [self push:wvc];
}

- (void)openClienURL:(NSURL*)url {
    NSLog(@"opening article view");
    ArticleViewController* vc = [[ArticleViewController alloc] init];
    vc.URL = url.PCURL;
    [self push:vc];
}

- (BOOL)webViewShouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSURL* url = [self processRedirects:request];
    BOOL result = [self webViewShouldStartLoadWithURL:url];
    if (result) {
        NSLog(@"%s: %@ %ld", __func__, request, navigationType);
    }
    return result;
}

- (NSURL*)processRedirects:(NSURLRequest*)request {
    if ([request.URL.scheme hasPrefix:@"http"]) {
        RedirectHandler* handler = [[RedirectHandler alloc] init];
        NSURLConnection* connection = [NSURLConnection connectionWithRequest:request delegate:handler];
        
        NSRunLoop* runLoop = [NSRunLoop currentRunLoop];
        NSDate* timeout = [NSDate dateWithTimeIntervalSinceNow:.1]; // fixme
        while (!handler.done && [[NSDate date] compare:timeout] == NSOrderedAscending && [runLoop runMode:NSDefaultRunLoopMode beforeDate:timeout]) {
            // nothing to do
        }
        
        if (handler.done) {
            NSURL* url = handler.URL;
            if (!url) {
                url = connection.currentRequest.URL;
            }
            NSLog(@"redirected to %@", url);
            return url;
        } else {
            NSLog(@"redirect timed out");
            [connection cancel];
        }
    }
    return request.URL;
}

- (BOOL)webViewShouldStartLoadWithURL:(NSURL*)url {
    if ([url isNativeClienURL]) {
        [self openClienURL:url];
        return NO;
    } else if ([url.scheme isEqualToString:@"clien"]) {
        [self handleInternalURL:url];
        return NO;
    } else if ([url.scheme isEqualToString:@"about"]) {
        NSLog(@"ignored %@", url);
        return NO;
    } else if ([url isAppStoreURL]) {
        [self presentStoreProductViewWithURL:url];
        return NO;
    }
    return YES;
}

- (void)handleInternalURL:(NSURL*)url {
    NSString* string = [url.resourceSpecifier stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSRange range = [string rangeOfString:@"?"];
    if (range.location != NSNotFound) {
        NSString* type = [string substringToIndex:range.location];
        NSString* info = [string substringFromIndex:range.location + range.length];
        if ([type isEqualToString:@"img"]) {
            // fixme implement proper image viewer
            [self openWebViewWithURL:[NSURL URLWithString:info]];
            return;
        } else if ([type isEqualToString:@"user"]) {
            NSLog(@"user %@", [string substringFromIndex:range.location + range.length]);
            Member* member = [[Member alloc] init];
            NSArray* array = [info componentsSeparatedByString:@","];
            member.ID = array[1];
            member.name = array[2];
            [self showUserMenu:member];
        } else if ([type isEqualToString:@"comment"]) {
            [self showCommentMenu:info];
        } else {
            NSLog(@"unknown internal URL: %@", url);
        }
    }
}

- (void)showUserMenu:(Member*)member {
    ActionSheetDelegate* delegate = [ActionSheetDelegate sharedDelegate];
    delegate.clickBlock = ^(UIActionSheet* actionSheet, NSInteger buttonIndex){
        if (buttonIndex == actionSheet.firstOtherButtonIndex) {
            [self showIDSearchResults:member];
        } else if (buttonIndex == actionSheet.firstOtherButtonIndex + 1) {
            [self showCommentSearchResults:member];
        } else if (buttonIndex == actionSheet.firstOtherButtonIndex + 2) {
            [self showUserInfo:member.ID];
        }
        // fixme more?
    };
    NSString* title = [member.name stringByAppendingString:@"님"];
    UIActionSheet* actionSheet = [[UIActionSheet alloc] initWithTitle:title delegate:delegate cancelButtonTitle:@"취소" destructiveButtonTitle:nil otherButtonTitles:
                                  @"아이디로 검색",
                                  @"댓글로 검색",
                                  @"회원정보",
                                  nil];
    [actionSheet showInView:self.view.window];
}

- (void)showCommentMenu:(NSString*)info {
    NSArray* array = [info componentsSeparatedByString:@","];
    ActionSheetDelegate* delegate = [ActionSheetDelegate sharedDelegate];
    UIActionSheet* actionSheet = [[UIActionSheet alloc] init];
    actionSheet.delegate = delegate;
    if ([array[1] rangeOfString:@"삭제"].length) {
        actionSheet.destructiveButtonIndex = [actionSheet addButtonWithTitle:@"삭제"];
    }
    NSInteger editButtonIndex = -1;
    if ([array[1] rangeOfString:@"수정"].length) {
        editButtonIndex = [actionSheet addButtonWithTitle:@"수정"];
    }
    NSInteger replyButtonIndex = -1;
    if ([array[1] rangeOfString:@"답변"].length) {
        replyButtonIndex = [actionSheet addButtonWithTitle:@"답변"];
    }
    if (actionSheet.numberOfButtons) {
        actionSheet.cancelButtonIndex = [actionSheet addButtonWithTitle:@"취소"];
        delegate.clickBlock = ^(UIActionSheet* actionSheet, NSInteger buttonIndex){
            if (buttonIndex == editButtonIndex) {
                [self performSelector:@selector(commentOnComment:) withObject:@[array[0], @"cu"]];
            } else if (buttonIndex == replyButtonIndex) {
                [self performSelector:@selector(commentOnComment:) withObject:@[array[0], @"c"]];
            } else if (buttonIndex == actionSheet.destructiveButtonIndex) {
                [self performSelector:@selector(confirmDeleteComment:) withObject:array[0]];
            }
            // fixme more?
        };
        [actionSheet showInView:self.view.window];
    }
}

- (void)showIDSearchResults:(Member*)member {
    [self showSearchResultsWithField:@"mb_id,1" memberID:member.ID title:[member.name stringByAppendingString:@"님의 글"]];
}

- (void)showCommentSearchResults:(Member*)member {
    [self showSearchResultsWithField:@"mb_id,0" memberID:member.ID title:[member.name stringByAppendingString:@"님의 댓글"]];
}

- (void)showSearchResultsWithField:(NSString*)field memberID:(NSString*)memberID title:(NSString*)title {
    if ([self respondsToSelector:@selector(URL)]) {
        NSString* url = [self URL].absoluteString;
        NSRange range = [url rangeOfString:@"&wr_id="];
        BoardViewController* vc = [[BoardViewController alloc] init];
        vc.URL = [NSURL URLWithString:[[url substringToIndex:range.location] stringByAppendingFormat:@"&sca=&sfl=%@&stx=%@", [field stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding], memberID]];
        vc.title = title; // fixme support image name
        [self push:vc];
    }
}

- (void)showUserInfo:(NSString*)memberID {
    WebViewController* vc = [[WebViewController alloc] init];
    vc.URL = [NSURL URLWithString:[@"http://www.clien.net/cs2/bbs/profile.php?mb_id=" stringByAppendingString:memberID]];
    [self push:vc];
}

- (void)presentStoreProductViewWithURL:(NSURL*)url {
    NSLog(@"opening product view");
    NSDictionary* paremeters = @{SKStoreProductParameterITunesItemIdentifier: [url.lastPathComponent substringFromIndex:2]};
    SKStoreProductViewController* spvc = [[SKStoreProductViewController alloc] init];
    spvc.delegate = self;
    [spvc loadProductWithParameters:paremeters completionBlock:^(BOOL result, NSError *error) {
        if (!result) {
            NSLog(@"%s %@", __func__, error);
            // fixme iOS 7 GM does not alert
//            UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:nil message:error.localizedDescription delegate:nil cancelButtonTitle:nil otherButtonTitles:@"확인", nil];
//            [alertView show];
        }
    }];
    [self presentViewController:spvc animated:YES completion:NULL];
}

- (void)productViewControllerDidFinish:(SKStoreProductViewController *)viewController {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)tryLoginWithID:(NSString *)memberID password:(NSString *)password completionBlock:(LoginCompletionBlock)block {
    // mb_id (max_length=20)
    // mb_password (same)
    NSURL* url;
    if ([self respondsToSelector:@selector(URL)]) {
        url = self.URL;
    } else {
        url = [NSURL URLWithString:@"http://clien.net/"];
    }
    AFHTTPClient* httpClient = [AFHTTPClient clientWithBaseURL:url];
    NSString* url2 = url.path;
    if (url.query) {
        url2 = [url2 stringByAppendingFormat:@"?%@", url.query];
    }
    NSDictionary* parameters = @{@"mb_id": memberID,
                                 @"mb_password": password,
                                 @"url": url2,
                                 //                                         @"auto_login": @1
                                 };
    [httpClient postPath:@"/cs2/bbs/login_check.php" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString* response = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        NSLog(@"login success %@", response);
        if (block) {
            if ([response rangeOfString:@"nowlogin=1'"].location == NSNotFound) {
                NSString* content = [response substringFrom:@"javascript'>alert('" to:@"'"];
                NSLog(@"%@", content);
                content = [content stringByReplacingOccurrencesOfString:@"\\n" withString:@" "];
                block(content);
            } else {
                NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
                if (![defaults boolForKey:SettingsManualLoginKey]) {
                    [defaults setObject:memberID forKey:SettingsMemberIDKey];
                    [defaults setObject:password forKey:SettingsPasswordKey];
                }
                block(nil);
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"login failure");
        if (block) {
            block(@"통신 오류?"); // fixme
        }
    }];
}

- (void)showLoginAlertViewWithMessage:(NSString*)message completionBlock:(LoginAlertViewCompletionBlock)block {
    AlertViewDelegate* delegate = [AlertViewDelegate sharedDelegate];
    if (!block) {
        block = ^(BOOL canceled, NSString* message) {
            if (!canceled && message) {
                UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:nil message:message delegate:nil cancelButtonTitle:nil otherButtonTitles:@"확인", nil];
                [alertView show];
            }
        };
    }
    delegate.clickBlock = ^(UIAlertView* alertView, NSInteger buttonIndex) {
        if (buttonIndex == alertView.firstOtherButtonIndex) {
            NSString* login = [alertView textFieldAtIndex:0].text;
            NSString* password = [alertView textFieldAtIndex:1].text;
            NSLog(@"%@ %@", login, password);
            if (login && password) {
                [self tryLoginWithID:login password:password completionBlock:^(NSString *message) {
                    block(NO, message);
                }];
            } else {
                block(NO, @"회원아이디와 패스워드를 입력하세요."); // fixme
            }
        } else {
            block(YES, nil);
        }
    };
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:nil message:message delegate:delegate cancelButtonTitle:@"취소" otherButtonTitles:@"확인", nil];
    alertView.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
    [alertView show];
}

@end
