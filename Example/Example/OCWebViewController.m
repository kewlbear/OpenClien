//
//  OCWebViewController.m
//  Example
//
// Copyright 2014 Changbeom Ahn
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

#import "OCWebViewController.h"
#import <OpenClien/OpenClien.h>
#import "OCArticleTableViewController.h"

@interface OCWebViewController ()

@end

@implementation OCWebViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [_webView loadRequest:[NSURLRequest requestWithURL:_URL]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if (navigationType == UIWebViewNavigationTypeLinkClicked && [request.URL isClienURL]) {
        OCArticleTableViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"article"];
        vc.article = [request.URL article];
        [self.navigationController pushViewController:vc animated:YES];
        return NO;
    }
    return YES;
}

- (IBAction)back:(id)sender {
    [_webView goBack];
}

- (IBAction)forward:(id)sender {
    [_webView goForward];
}

- (IBAction)safari:(id)sender {
    if (![[UIApplication sharedApplication] openURL:_URL]) {
        NSString *message = [NSString stringWithFormat:@"%@을 열지 못했습니다.", _URL];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:message delegate:nil cancelButtonTitle:nil otherButtonTitles:@"확인", nil];
        [alert show];
    }
}

@end
