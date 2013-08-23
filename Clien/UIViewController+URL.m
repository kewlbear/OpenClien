//
//  UIViewController+URL.m
//  Clien
//
//  Created by 안창범 on 13. 8. 21..
//  Copyright (c) 2013년 안창범. All rights reserved.
//

#import "UIViewController+URL.h"
#import "WebViewController.h"
#import "BoardViewController.h"
#import "ArticleViewController.h"
#import "UIViewController+Stack.h"

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
    return [@[@"www.clien.net", @"m.clien.net", @"clien.career.co.kr"] containsObject:self.host] &&
    [self.lastPathComponent hasPrefix:@"board"] &&
    [self.query rangeOfString:@"wr_id="].location != NSNotFound;
}

@end

@interface RedirectHandler : NSObject <NSURLConnectionDataDelegate>

@property (nonatomic) BOOL done;

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
    NSLog(@"%s", __func__);
    _done = YES;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    NSLog(@"%s", __func__);
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    // fixme stop loading?
    NSLog(@"%s", __func__);
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
        NSLog(@"%s: %@ %d", __func__, request, navigationType);
    }
    return result;
}

- (NSURL*)processRedirects:(NSURLRequest*)request {
    if ([request.URL.scheme hasPrefix:@"http"]) {
        RedirectHandler* handler = [[RedirectHandler alloc] init];
        NSURLConnection* connection = [NSURLConnection connectionWithRequest:request delegate:handler];
        
        NSRunLoop* runLoop = [NSRunLoop currentRunLoop];
        NSDate* timeout = [NSDate dateWithTimeIntervalSinceNow:.1];
        while (!handler.done && [[NSDate date] compare:timeout] == NSOrderedAscending && [runLoop runMode:NSDefaultRunLoopMode beforeDate:timeout]) {
            // nothing to do
        }
        
        if (handler.done) {
            NSLog(@"redirected to %@", connection.currentRequest.URL);
            return connection.currentRequest.URL;
        } else {
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
    NSString* string = url.resourceSpecifier;
    NSRange range = [string rangeOfString:@"?"];
    if (range.location != NSNotFound) {
        if ([[string substringToIndex:range.location] isEqualToString:@"img"]) {
            // fixme implement proper image viewer
            [self openWebViewWithURL:[NSURL URLWithString:[string substringFromIndex:range.location + 1]]];
            return;
        }
    }
    //        while ([webView stringByEvaluatingJavaScriptFromString:@"console._logs.length"].intValue > 0) {
    //            NSLog(@"%s: %@", __func__, [webView stringByEvaluatingJavaScriptFromString:@"console._logs.shift()"]);
    //        }
}

- (void)presentStoreProductViewWithURL:(NSURL*)url {
    NSLog(@"opening product view");
    NSDictionary* paremeters = @{SKStoreProductParameterITunesItemIdentifier: [url.lastPathComponent substringFromIndex:2]};
    SKStoreProductViewController* spvc = [[SKStoreProductViewController alloc] init];
    spvc.delegate = self;
    [spvc loadProductWithParameters:paremeters completionBlock:^(BOOL result, NSError *error) {
        // fixme handle result == NO
        NSLog(@"%d %@", result, error);
    }];
    [self presentViewController:spvc animated:YES completion:NULL];
}

- (void)productViewControllerDidFinish:(SKStoreProductViewController *)viewController {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

@end
