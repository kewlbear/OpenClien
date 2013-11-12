//
//  WebViewController.m
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

#import "WebViewController.h"
#import "UIViewController+Stack.h"
#import "UIViewController+URL.h"
#import "UIViewController+GAI.h"

@interface WebViewController () {
    UIActivityIndicatorView* indicator;
    UIBarButtonItem* backItem;
    UIBarButtonItem* forwardItem;
    BOOL _loaded;
}

@end

@implementation WebViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        self.navigationItem.titleView = indicator;
        self.contentSizeForViewInPopover = CGSizeMake(1024, 1024);
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"웹" style:UIBarButtonItemStylePlain target:nil action:NULL];
        [self sendHitWithScreenName:@"Web"];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIWebView* webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    webView.delegate = self;
    webView.scalesPageToFit = YES;
    webView.scrollView.delegate = self;
    [self.view addSubview:webView];
    self.webView = webView;
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:_webView action:@selector(reload)];
    backItem = [[UIBarButtonItem alloc] initWithTitle:@"<" style:UIBarButtonItemStylePlain target:_webView action:@selector(goBack)];
    backItem.enabled = NO;
    forwardItem = [[UIBarButtonItem alloc] initWithTitle:@">" style:UIBarButtonItemStylePlain target:_webView action:@selector(goForward)];
    forwardItem.enabled = NO;
    UIBarButtonItem* flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:NULL];
    UIBarButtonItem* fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:NULL];
    fixedSpace.width = 10;
    UIBarButtonItem* safariItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(openInSafari)];
    self.toolbarItems = [NSArray arrayWithObjects:backItem, fixedSpace, forwardItem, flexibleSpace, safariItem, nil];
    
    [self setGestureRecognizer];
    
    if (_URL.isFileURL) {
        NSData* data = [NSData dataWithContentsOfURL:_URL];
        [webView loadData:data MIMEType:@"text/plain" textEncodingName:@"utf-8" baseURL:nil];
    } else {
        NSURLRequest* request = [NSURLRequest requestWithURL:_URL];
        [webView loadRequest:request];
    }
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    NSLog(@"%s: %f", __func__, scrollView.zoomScale);
    self.swipeGestureRecognizer.enabled = scrollView.zoomScale <= 1;
}

- (void)openInSafari {
    [[UIApplication sharedApplication] openURL:_webView.request.URL];
}

- (void)viewWillAppear:(BOOL)animated {
    self.navigationController.toolbarHidden = NO;
}

- (void)viewWillDisappear:(BOOL)animated {
    self.navigationController.toolbarHidden = YES;
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if (_loaded) {
        return [self webViewShouldStartLoadWithRequest:request navigationType:navigationType];
    }
    return YES;
}

- (void)productViewControllerDidFinish:(SKStoreProductViewController *)viewController {
    [self dismissViewControllerAnimated:YES completion:NULL];
    [self.navigationController popViewControllerAnimated:NO];
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    self.navigationItem.titleView = indicator;
    [indicator startAnimating];
    self.swipeGestureRecognizer.enabled = YES; // fixme check _loaded?
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [indicator stopAnimating];
    backItem.enabled = webView.canGoBack;
    forwardItem.enabled = webView.canGoForward;
    self.title = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    self.navigationItem.titleView = nil;
    _loaded = YES;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    NSLog(@"%s: %@", __func__, error);
    [indicator stopAnimating];
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
