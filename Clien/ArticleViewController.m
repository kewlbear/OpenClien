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
#import "ArticleCell.h"
#import "CommentCell.h"
#import "TextParagraph.h"
#import "ImageParagraph.h"
#import "UIImageView+AFNetworking.h"
#import "GTMNSString+HTML.h"
#import "UIViewController+Stack.h"

@interface ArticleViewController () {
    UIWebView* webView;
}

@end

@implementation ArticleViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.toolbarItems = [NSArray arrayWithObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(openWebView)]];
    }
    return self;
}

- (void)loadView {
    [super loadView];
    
    webView = [[UIWebView alloc] initWithFrame:CGRectZero];
    webView.delegate = self;
    self.view = webView;
}

- (BOOL)webView:(UIWebView *)webView_ shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if ([request.URL.scheme isEqualToString:@"about"]) {
        return NO;
    }
    if ([request.URL.scheme isEqualToString:@"clien"]) {
        while ([webView stringByEvaluatingJavaScriptFromString:@"console._logs.length"].intValue > 0) {
            NSLog(@"%s: %@", __func__, [webView stringByEvaluatingJavaScriptFromString:@"console._logs.shift()"]);
        }
        return NO;
    }
    NSLog(@"%s: %@ %d", __func__, request, navigationType);
    return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView_ {
    NSURL* URL = [[NSBundle mainBundle] URLForResource:@"Clien" withExtension:@"js"];
    NSError* error;
    NSString* script = [NSString stringWithContentsOfURL:URL encoding:NSUTF8StringEncoding error:&error];
    if (script) {
        NSString* string = [webView stringByEvaluatingJavaScriptFromString:script];
        NSLog(@"%s: eval()=%@", __func__, string);
    } else {
        NSLog(@"%s: %@", __func__, error);
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setTitleView];
    [self setGestureRecognizer];
    [self reload];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.navigationController.toolbarHidden = NO;
    [self performSelector:@selector(hideToolbar) withObject:nil afterDelay:.5];
}

- (void)hideToolbar {
    [self.navigationController setToolbarHidden:YES animated:YES];
}

- (void)openWebView {
    WebViewController* controller = [[WebViewController alloc] initWithNibName:nil bundle:nil];
    controller.URL = _URL;
//    [self.navigationController pushViewController:controller animated:YES];
    [self push:controller];
}

- (void)reload {
    NSLog(@"%s: %@", __func__, _URL);
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:_URL];
    [request setValue:@"utf-8" forHTTPHeaderField:@"accept-charset"];
    NSURLConnection* connection = [NSURLConnection connectionWithRequest:request delegate:self];
    if (connection) {
        receivedData = [NSMutableData data];
        UIActivityIndicatorView* indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        [indicator startAnimating];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:indicator];
    } else {
        NSLog(@"%s: connection failed", __func__);
        [self setRefreshButton];
    }
}

- (void)setRefreshButton {
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(reload)];
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
    [self setRefreshButton];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    NSString* response = [[NSString alloc] initWithData:receivedData encoding:NSUTF8StringEncoding];
    if (!response) {
        iconv_t cd = iconv_open("UTF-8", "UTF-8");  // TODO: convert to unichar
        if (cd != (iconv_t) -1) {
            NSMutableData* data = [NSMutableData dataWithLength:receivedData.length];
            const char* inbuf = [receivedData bytes];
            size_t inbytesleft = receivedData.length;
            char* outbuf = [data mutableBytes];
            size_t outbytesleft = data.length;
            while (inbytesleft > 0) {
                size_t n = iconv(cd, (char**) &inbuf, &inbytesleft, &outbuf, &outbytesleft);
                NSLog(@"%s: iconv=%lu", __func__, n);
                if (n == (size_t) -1) {
                    NSLog(@"%s: %d %s", __func__, errno, strerror(errno));
                    if (YES || errno == EILSEQ) {
                        NSLog(@"%s: %x", __func__, (unsigned char) *inbuf);
                        ++inbuf;
                        --inbytesleft;
                        *outbuf++ = '?';
                        --outbytesleft;
                        continue;
                    }
                    break;
                }
            }
            iconv_close(cd);
            data.length = outbuf - (char*) [data mutableBytes];
            response = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        } else {
            NSLog(@"%s: %s", __func__, strerror(errno));
        }
    }
    NSLog(@"%s: response=%@", __func__, response);
    static NSString* prefix;
    if (!prefix) {
        NSURL* URL = [[NSBundle mainBundle] URLForResource:@"Article" withExtension:@"html"];
        NSError* error;
        prefix = [NSString stringWithContentsOfURL:URL encoding:NSUTF8StringEncoding error:&error];
        if (!prefix) {
            NSLog(@"%s: %@", __func__, error);
        }
    }
    NSMutableString* html = [NSMutableString stringWithString:prefix];

    NSString* content = [response substringFrom:@"<div class=\"board_main\">" to:@"<div class=\"view_content\">"];
    if (content) {
        [html appendString:content];
    } else {
        NSLog(@"%s: no content", __func__);
    }
    
    NSScanner* scanner = [NSScanner scannerWithString:[response substringFrom:@"<div id=\"resContents\"" to:@"<!-- 광고 영역 -->"]];
    NSLog(@"%s: %@", __func__, scanner.string);
    [scanner skip:@"<"];
    if ([scanner scanString:@"div class=\"attachedImage\">" intoString:NULL]) {
        while ([scanner scanString:@"<img" intoString:NULL]) {
            [scanner skip:@"src="];
            NSString* quote;
            [scanner scanCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"\"'"] intoString:&quote];
            NSString* src;
            [scanner scanUpToString:quote intoString:&src];
            NSLog(@"%s: attach %@", __func__, src);
            [html appendFormat:@"<img src=\"%@\" />", src];
        }
    }
    [scanner skip:@"span id=\"writeContents\""];
    [scanner skip:@">"];

    [html appendString:[scanner.string substringFromIndex:scanner.scanLocation]];
    
    NSString* comments = [response substringFrom:@"<div class=\"reply_head\"" to:@"<script"];
    if (comments) {
        [html appendString:@"<hr />"];
        [html appendString:@"<div class=\"reply_head\""];
        [html appendString:comments];
    } else {
        NSLog(@"%s: comments not found", __func__);
    }
    
//    [html replaceOccurrencesOfString:@"width" withString:@"w" options:0 range:NSMakeRange(0, html.length)];
//    [html replaceOccurrencesOfString:@"height" withString:@"h" options:0 range:NSMakeRange(0, html.length)];
    [html replaceOccurrencesOfString:@"<iframe" withString:@"<if" options:0 range:NSMakeRange(0, html.length)];
    NSLog(@"%s: %@", __func__, html);
    [webView loadHTMLString:html baseURL:_URL];
    
    [self setRefreshButton];
}

- (void)setTitleView {
    UILabel* label = [[UILabel alloc] initWithFrame:UIEdgeInsetsInsetRect(self.navigationController.navigationBar.bounds, UIEdgeInsetsMake(5, 0, 5, 0))];
    label.text = self.title;
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    label.numberOfLines = 0;
    label.font = [UIFont systemFontOfSize:14];
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor whiteColor];
    label.textAlignment = UITextAlignmentCenter;
//    label.shadowColor = [UIColor blackColor];
    self.navigationItem.titleView = label;
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
