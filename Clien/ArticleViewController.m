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

@interface ArticleViewController ()

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

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UITextView* textView = [[UITextView alloc] initWithFrame:self.view.bounds];
    textView.editable = NO;
    textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:textView];
    self.textView = textView;
        
    [self reload];
}

- (void)viewWillAppear:(BOOL)animated {
    self.navigationController.toolbarHidden = NO;
}

- (void)viewWillDisappear:(BOOL)animated {
    self.navigationController.toolbarHidden = YES;
}

- (void)openWebView {
    WebViewController* controller = [[WebViewController alloc] initWithNibName:nil bundle:nil];
    controller.href = [self URL];
    [self.navigationController pushViewController:controller animated:YES];
}

- (NSString*)URL {
    return [self.href stringByReplacingOccurrencesOfString:@".." withString:@"http://clien.career.co.kr/cs2"];
}

- (void)reload {
    NSURL* URL = [NSURL URLWithString:[self URL]];
    NSLog(@"%s: %@ %@", __func__, self.href, URL);
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:URL];
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
                    if (errno == EILSEQ) {
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
    NSScanner* scanner = [NSScanner scannerWithString:[response substringFrom:@"<span id=\"writeContents\"" to:@"</span>"]];
    NSLog(@"%s: %@", __func__, response);
    [scanner skip:@">"];
    while (!scanner.isAtEnd) {
        NSString* string;
        if ([scanner scanUpToString:@"<" intoString:&string]) {
            self.textView.text = [self.textView.text stringByAppendingString:string];
        }
        if ([scanner scanString:@"<" intoString:NULL]) {
            if ([scanner scanString:@"!--" intoString:NULL]) {
                [scanner skip:@"-->"];
            } else {
                while ([scanner scanUpToString:@">" intoString:&string]) {
                    NSRange range = [string rangeOfString:@"\""];
                    if (range.location != NSNotFound) {
                        int n = 1;
                        while (1) {
                            range = [string rangeOfString:@"\"" options:0 range:NSMakeRange(range.location + 1, [string length] - range.location - 1)];
                            if (range.location == NSNotFound) {
                                break;
                            }
                            ++n;
                        }
                        if (n % 2) {
                            [scanner skip:@"\""];
                            continue;
                        }
                    }
                    [scanner skip:@">"];
                    break;
                }
            }
        }
    }
    NSLog(@"%s: 본문 스캔 끝", __func__);
    scanner = [NSScanner scannerWithString:[response substringFrom:@"<div id=\"comment_wrapper\">" to:@"<script"]];
    while (!scanner.isAtEnd) {
        [scanner skip:@"<li class=\"user_id\">"];
        NSString* user;
        if (![scanner scanUpToString:@"</li>" intoString:&user]) {
            break;
        }
        NSLog(@"%s: %@님 댓글", __func__, user);
        self.textView.text = [self.textView.text stringByAppendingFormat:@"\n\n%@", user];
        [scanner skip:@"<li> ("];
        NSString* timestamp;
        [scanner scanUpToString:@")" intoString:&timestamp];
        self.textView.text = [self.textView.text stringByAppendingFormat:@" %@", timestamp];
        [scanner skip:@"<div class=\"reply_content\">"];
        NSString* content;
        [scanner scanUpToString:@"<span" intoString:&content];
        self.textView.text = [self.textView.text stringByAppendingFormat:@"\n%@", content];
    }
    [self setRefreshButton];
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
