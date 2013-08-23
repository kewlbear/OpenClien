//
//  ArticleViewController.m
//  Clien
//
//  Created by 안창범 on 12. 8. 21..
//  Copyright (c) 2012년 안창범. All rights reserved.
//

#import "ArticleViewController.h"
#import "NSScanner+Skip.h"
#import "NSString+SubstringFromTo.h"
#import "WebViewController.h"
#import <iconv.h>
#import "Comment.h"
#import "UIImageView+AFNetworking.h"
#import "GTMNSString+HTML.h"
#import "UIViewController+Stack.h"
#import "AFHTTPClient.h"
#import "ComposeViewController.h"
#import "UIViewController+URL.h"

@interface ArticleViewController () {
    UIWebView* _webView;
}

@property (strong, nonatomic) UIRefreshControl* refreshControl;

@end

@implementation ArticleViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        UIBarButtonItem* comment = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(compose:)];
        UIBarButtonItem* actions = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(showActions:)];
        UIBarButtonItem* flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:NULL];
        self.toolbarItems = @[comment, flexibleSpace, actions];
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"logo"] landscapeImagePhone:nil style:UIBarButtonItemStylePlain target:nil action:NULL];
    }
    return self;
}

- (void)compose:(id)sender {
    ComposeViewController* vc = [[UIStoryboard storyboardWithName:@"SharedStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"Compose"];
    self.navigationController.modalPresentationStyle = UIModalPresentationCurrentContext;
    [self presentViewController:vc animated:YES completion:NULL];
}

- (void)showActions:(id)sender {
    UIActionSheet* actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"취소" destructiveButtonTitle:@"삭제" otherButtonTitles:@"웹", nil];
    [actionSheet showFromBarButtonItem:sender animated:YES];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == actionSheet.destructiveButtonIndex) {
        [self notYet];
    } else if (buttonIndex != actionSheet.cancelButtonIndex) {
        switch (buttonIndex - actionSheet.firstOtherButtonIndex) {
            case 0:
                [self openWebView];
                break;
                
            default:
                NSLog(@"unexpected button index: %d", buttonIndex);
                break;
        }
    }
}

- (void)notYet {
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:nil message:@"미구현" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"확인", nil];
    [alertView show];
}

- (void)loadView {
    [super loadView];
    
    _webView = [[UIWebView alloc] initWithFrame:CGRectZero];
    _webView.delegate = self;
    _webView.scrollView.backgroundColor = [UIColor whiteColor];
    // hide shadow - http://stackoverflow.com/questions/3009063/remove-gradient-background-from-uiwebview
    for (UIView* subview in _webView.scrollView.subviews) {
        if ([subview isKindOfClass:[UIImageView class]]) {
            subview.hidden = YES;
        }
    }
    
    if (!_refreshControl) {
        self.refreshControl = [[UIRefreshControl alloc] init];
    }
    [_refreshControl addTarget:self action:@selector(reload) forControlEvents:UIControlEventValueChanged];
    [_webView.scrollView addSubview:_refreshControl];
    
    self.view = _webView;
}

- (BOOL)webView:(UIWebView *)webView_ shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if (navigationType == UIWebViewNavigationTypeLinkClicked || [request.URL.scheme isEqualToString:@"clien"]) { // fixme
        // fixme handle redirects
        [self openURL:request.URL];
        return NO;
    }
    return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    NSLog(@"%s: %@", __func__, webView.request);
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    NSLog(@"%s: %@", __func__, error);
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setTitleView];
    [self setGestureRecognizer];
    [self reload];
}

//- (void)viewWillAppear:(BOOL)animated {
//    [super viewWillAppear:animated];
//    
//    self.navigationController.toolbarHidden = NO;
//}
//
//- (void)viewWillDisappear:(BOOL)animated {
//    [super viewWillDisappear:animated];
//    
//    self.navigationController.toolbarHidden = YES;
//}

- (void)openWebView {
    WebViewController* vc = [[WebViewController alloc] init];
    vc.URL = _URL;
    [self push:vc];
}

- (void)reload {
    NSLog(@"%s: %@", __func__, _URL);
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:_URL];
//    [request setValue:@"utf-8" forHTTPHeaderField:@"accept-charset"];
    NSURLConnection* connection = [NSURLConnection connectionWithRequest:request delegate:self];
    if (connection) {
        [_refreshControl beginRefreshing];
        receivedData = [NSMutableData data];
    } else {
        NSLog(@"%s: connection failed", __func__);
        [_refreshControl endRefreshing];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*) response;
    NSLog(@"%s: %d %@", __func__, httpResponse.statusCode, httpResponse.allHeaderFields);
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [receivedData appendData:data];
    NSLog(@"%s: %u", __func__, data.length);
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSLog(@"%s: %@", __func__, error);
    connection = nil;
    [_refreshControl endRefreshing];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    connection = nil;
    NSString* response = [[NSString alloc] initWithData:receivedData encoding:NSUTF8StringEncoding];
    if (!response) {
        NSLog(@"invalid encoding");
        iconv_t cd = iconv_open("UTF-16", "UTF-8");
        if (cd != (iconv_t) -1) {
            NSMutableData* data = [NSMutableData dataWithLength:2 * receivedData.length];
            const char* inbuf = [receivedData bytes];
            size_t inbytesleft = receivedData.length;
            char* outbuf = [data mutableBytes];
            size_t outbytesleft = data.length;
            int x = -1;
            while (inbytesleft > 0) {
                size_t n = iconv(cd, (char**) &inbuf, &inbytesleft, &outbuf, &outbytesleft);
                if (n == (size_t) -1) {
                    if (errno == EILSEQ) {
                        NSLog(@"%s: %x", __func__, (unsigned char) *inbuf);
                        ++inbuf;
                        --inbytesleft;
                        if (x < 0) {
                            x = (outbuf - (char*) data.mutableBytes) / 2;
                        }
                        *((unichar*) outbuf) = [@"�" characterAtIndex:0];
                        outbuf += sizeof(unichar);
                        outbytesleft -= sizeof(unichar);
                        continue;
                    } else if (errno == EINVAL) {
                        NSLog(@"einval");
                    } else if (errno == E2BIG) {
                        NSLog(@"e2big");
                    } else {
                        NSLog(@"%s: %d %s", __func__, errno, strerror(errno));
                    }
                    break;
                }
            }
            iconv_close(cd);
            data.length = outbuf - (char*) [data mutableBytes];
            // fixme check performance
            response = [[NSString alloc] initWithData:data encoding:NSUTF16StringEncoding];
            if (x >= 0) {
                NSRange range;
                range.location = MAX(x - 500, 0);
                range.length = MIN(1000, response.length - range.location);
                NSLog(@"x=%d %@", x, [response substringWithRange:range]);
            }
        } else {
            NSLog(@"%s: %s", __func__, strerror(errno));
        }
    }
    receivedData = nil;
//    NSLog(@"%s: response=%@", __func__, response);
    static NSString* prefix;
    if (!prefix) {
        NSURL* URL = [[NSBundle mainBundle] URLForResource:@"Article" withExtension:@"html"];
        NSError* error;
        prefix = [NSString stringWithContentsOfURL:URL encoding:NSUTF8StringEncoding error:&error];
        if (!prefix) {
            NSLog(@"%s: %@", __func__, error);
        }
        // fixme
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            prefix = [prefix stringByReplacingOccurrencesOfString:@"device-width" withString:@"700"];
        }
    }
    NSMutableString* html = [NSMutableString stringWithString:prefix];

    NSString* content = [response substringFrom:@"<div class=\"board_main\">" to:@"<!-- 광고 영역 -->"];
    if (content) {
        NSRange range = [content rangeOfString:@"<ul class=\"view_content_btn2\""];
        if (range.location != NSNotFound) {
            content = [content substringToIndex:range.location];
        }
        [html appendString:content];
    } else {
        NSLog(@"%s: no content", __func__);
        [self showLoginAlertViewWithResponse:response];
    }
    
    NSString* comments = [response substringFrom:@"<div class=\"reply_head\"" to:@"<script"];
    if (comments) {
        [html appendString:@"<hr />"];
        [html appendString:@"<div class=\"reply_head\""];
        [html appendString:comments];
    } else {
        NSLog(@"%s: comments not found", __func__);
    }
    
    if ([response rangeOfString:@"<div class=\"reply_write\">"].location == NSNotFound) {
        NSLog(@"can't reply");
    } else {
        NSLog(@"can reply");
    }
    
//    [html replaceOccurrencesOfString:@"width" withString:@"w" options:0 range:NSMakeRange(0, html.length)];
//    [html replaceOccurrencesOfString:@"height" withString:@"h" options:0 range:NSMakeRange(0, html.length)];
    [html replaceOccurrencesOfString:@"<iframe" withString:@"<if" options:0 range:NSMakeRange(0, html.length)];
//    NSLog(@"%s: %@", __func__, html);
    [_webView loadHTMLString:html baseURL:_URL];
    
    [_refreshControl endRefreshing];
}

- (void)showLoginAlertViewWithResponse:(NSString*)response {
    NSString* content = [response substringFrom:@"javascript'>alert('" to:@"'"];
    NSLog(@"%@", content);
    content = [content stringByReplacingOccurrencesOfString:@"\\n" withString:@" "];
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:nil message:content delegate:nil cancelButtonTitle:@"취소" otherButtonTitles:@"확인", nil];
    alertView.delegate = self;
    alertView.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
    [alertView show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == alertView.firstOtherButtonIndex) {
        NSString* login = [alertView textFieldAtIndex:0].text;
        NSString* password = [alertView textFieldAtIndex:1].text;
        NSLog(@"%@ %@", login, password);
        if (login.length > 0 && password.length > 0) {
            // https://www.clien.net/cs2/bbs/login_check.php
            // url=%2f
            // mb_id (max_length=20)
            // mb_password (same)
            AFHTTPClient* httpClient = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:@"https://www.clien.net/cs2/bbs/login_check.php"]];
            [httpClient postPath:@"" parameters:@{@"mb_id": login, @"mb_password": password} success:^(AFHTTPRequestOperation *operation, id responseObject) {
                NSString* response = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
                NSLog(@"login success %@", response);
                if ([response rangeOfString:@"?nowlogin=1'"].location == NSNotFound) {
                    [self showLoginAlertViewWithResponse:response];
                } else {
                    [self reload];
                }
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                // fixme
                NSLog(@"login failure");
            }];
            return;
        }
    }

    [self.navigationController popViewControllerAnimated:YES];
}

- (void)setTitleView {
//    UILabel* label = [[UILabel alloc] initWithFrame:UIEdgeInsetsInsetRect(self.navigationController.navigationBar.bounds, UIEdgeInsetsMake(5, 0, 5, 0))];
//    label.text = self.title;
//    label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
//    label.numberOfLines = 0;
//    label.font = [UIFont systemFontOfSize:14];
//    label.backgroundColor = [UIColor clearColor];
//    label.textColor = [UIColor whiteColor];
//    label.textAlignment = UITextAlignmentCenter;
////    label.shadowColor = [UIColor blackColor];
//    self.navigationItem.titleView = label;
    UIImageView* imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo"]];
    self.navigationItem.titleView = imageView;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
