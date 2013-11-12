//
//  ArticleViewController.m
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

enum {
    CommentTag,
    ArticleTag,
    ScrapTag
};

@interface OpenInSafariActivity : UIActivity {
    NSURL* _url;
}

@end

@implementation OpenInSafariActivity

- (NSString*)activityType {
    return @"open in safari";
}

- (NSString*)activityTitle {
    return @"Safari";
}

- (UIImage*)activityImage {
    return [UIImage imageNamed:@"logo"]; // fixme change image
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems {
    // fixme check item type?
    return [[UIApplication sharedApplication] canOpenURL:activityItems[0]];
}

- (void)prepareWithActivityItems:(NSArray *)activityItems {
    _url = activityItems[0];
}

- (void)performActivity {
    [self activityDidFinish:[[UIApplication sharedApplication] openURL:_url]];
}

@end

@interface ArticleViewController () {
    UIWebView* _webView;
    NSString* _response;
    NSString* _selectedCommentID;
    NSArray* _memos;
    UITextField* __weak _memoField;
}

@property (strong, nonatomic) UIRefreshControl* refreshControl;

@end

@implementation ArticleViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"logo"] landscapeImagePhone:nil style:UIBarButtonItemStylePlain target:nil action:NULL];
        [self updateToolbarItems];
        self.screenName = @"Article";
    }
    return self;
}

- (void)scrap:(id)sender {
    if ([self canScrap]) {
        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:nil message:@"이 글을 스크랩합니다." delegate:self cancelButtonTitle:@"취소" otherButtonTitles:@"확인", nil];
        alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
        _memoField = [alertView textFieldAtIndex:0];
        _memoField.inputView = [self memoPickerView];
        UIToolbar* toolbar = [[UIToolbar alloc] init];
        UISegmentedControl* segmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"선택", @"입력"]];
        [segmentedControl addTarget:self action:@selector(memoSegmentedControlChanged:) forControlEvents:UIControlEventValueChanged];
        segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
        segmentedControl.selectedSegmentIndex = 0;
        toolbar.items = @[[[UIBarButtonItem alloc] initWithCustomView:segmentedControl]];
        [toolbar sizeToFit];
        _memoField.inputAccessoryView = toolbar;
        _memoField.placeholder = @"메모";
        alertView.tag = ScrapTag;
        [alertView show];
        NSString* path = [_response substringFrom:@"\"win_scrap('" to:@"'"];
        [[AFHTTPClient clientWithBaseURL:_URL] getPath:path parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSString* responseString = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
            NSLog(@"%@", responseString);
            NSString* x = [responseString substringFrom:@"선택하기</option>" to:@"</select>"];
            NSMutableArray* array = [NSMutableArray array];
            for (NSString* option in [x componentsSeparatedByString:@"><"]) {
                [array addObject:[option substringFrom:@"'" to:@"'"]];
            }
            _memos = array;
            [(UIPickerView*)_memoField.inputView reloadAllComponents];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"%@", error);
            // fixme
        }];
    } else {
        // fixme other restrictions?
        [self showLoginAlertViewWithMessage:@"로그인이 필요한 기능입니다." completionBlock:NULL];
    }
}

- (void)memoSegmentedControlChanged:(UISegmentedControl*)segmentedControl {
    [_memoField resignFirstResponder];
    
    if (_memoField.inputView) {
        _memoField.inputView = nil;
    } else {
        _memoField.inputView = [self memoPickerView];
    }
    
    [_memoField becomeFirstResponder];
}

- (UIPickerView*)memoPickerView {
    UIPickerView* pickerView = [[UIPickerView alloc] init];
    pickerView.dataSource = self;
    pickerView.delegate = self;
    return pickerView;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return _memos.count;
}

- (NSString*)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return _memos[row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    _memoField.text = _memos[row];
}

- (BOOL)canScrap {
    return [_response rangeOfString:@"win_scrap('"].length;
}

- (void)compose:(id)sender {
    if ([self canComment]) {
        [self presentComposeViewControllerWithBlock:^(ComposeViewController *vc) {
            vc.url = [NSURL URLWithString:@"./write_comment_update.php" relativeToURL:_URL];
            vc.successBlock = ^{
                [self dismissViewControllerAnimated:YES completion:NULL];
                [self reload];
            };
            vc.extraParameters = @{@"w": @"c"};
            vc.isComment = YES;
            vc.title = @"댓글 쓰기";
        }];
    } else {
        // fixme other restrictions?
        [self showLoginAlertViewWithMessage:@"로그인이 필요한 기능입니다." completionBlock:NULL];
    }
}

- (void)commentOnComment:(NSArray*)info {
    [self presentComposeViewControllerWithBlock:^(ComposeViewController *vc) {
        vc.url = [NSURL URLWithString:@"./write_comment_update.php" relativeToURL:_URL];
        vc.successBlock = ^{
            [self dismissViewControllerAnimated:YES completion:NULL];
            [self reload];
        };
        vc.extraParameters = @{@"comment_id": info[0], @"w": info[1]};
        if ([info[1] isEqualToString:@"cu"]) {
            NSString* script = [NSString stringWithFormat:@"document.getElementById('save_comment_%@').innerHTML", info[0]];
            vc.loadBlock = ^(ComposeViewController* vc) {
                vc.textView.text = [_webView stringByEvaluatingJavaScriptFromString:script];
            };
            vc.title = @"댓글 수정";
        } else {
            vc.title = @"대댓글 쓰기";
        }
        vc.isComment = YES;
    }];
}

- (void)confirmDeleteComment:(NSString*)ID {
    _selectedCommentID = ID;
    UIActionSheet* actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"취소" destructiveButtonTitle:@"삭제" otherButtonTitles:nil];
    actionSheet.tag = CommentTag;
    [actionSheet showInView:self.view.window];
}

- (void)confirmDeleteArticle:(id)sender {
    UIActionSheet* actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"취소" destructiveButtonTitle:@"삭제" otherButtonTitles:nil];
    actionSheet.tag = ArticleTag;
    [actionSheet showFromBarButtonItem:sender animated:YES];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (actionSheet.tag == ArticleTag) {
        if (buttonIndex == actionSheet.destructiveButtonIndex) {
            [self deleteArticle];
        }
    } else if (actionSheet.tag == CommentTag) {
        if (buttonIndex == actionSheet.destructiveButtonIndex) {
            [self deleteComment];
        }
    }
}

- (void)deleteComment {
    // fixme
    NSString* script = [NSString stringWithFormat:
                        @"(function() {"
                        "var a = document.getElementById('save_comment_%@')."
                        "parentNode.getElementsByTagName('a');"
                        "for (var i = 0; i < a.length; ++i) {"
                        "if (a[i].href.match(/delete_comment/)) {"
                        "return a[i].href.split(\"'\")[1];"
                        "}" // if
                        "}" // for
                        "})()", // function
                        _selectedCommentID];
    NSString* path = [_webView stringByEvaluatingJavaScriptFromString:script];
    AFHTTPClient* client = [AFHTTPClient clientWithBaseURL:_URL];
    [client getPath:path parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString* responseString = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        NSLog(@"%@", responseString);
        // fixme check error
        [self reload];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@", error);
        // fixme
        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:nil message:error.localizedDescription delegate:nil cancelButtonTitle:nil otherButtonTitles:@"확인", nil];
        [alertView show];
    }];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == ScrapTag) {
        if (buttonIndex == alertView.firstOtherButtonIndex) {
            [self submitScrap];
        }
    }
}

- (void)submitScrap {
    NSString* wr_mb_id = [_webView stringByEvaluatingJavaScriptFromString:@"document.getElementsByClassName('user_info')[0].innerHTML.split(\"'\")[1]"];
    NSMutableDictionary* parameters = [@{@"wr_mb_id": wr_mb_id,
                                       @"wr_content": _memoField.text
                                       // fixme more hidden parameters?
                                       }
                                       mutableCopy];
    NSArray* array = [_URL.query componentsSeparatedByString:@"&"];
    for (NSString* parameter in array) {
        NSArray* nameValue = [parameter componentsSeparatedByString:@"="];
        NSLog(@"%@", nameValue);
        parameters[nameValue[0]] = nameValue[1];
    }
    parameters[@"wr_subject"] = self.title;
    [[AFHTTPClient clientWithBaseURL:_URL] postPath:@"./scrap_popin_update.php" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString* responseString = [[NSString alloc] initWithData:receivedData encoding:NSUTF8StringEncoding];
        NSLog(@"%@", responseString);
        // fixme provide proper viewer
        WebViewController* vc = [[WebViewController alloc] init];
        vc.URL = [NSURL URLWithString:@"http://m.clien.net/cs3/scrap"];
        [self.navigationController pushViewController:vc animated:YES];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:nil message:error.localizedDescription delegate:nil cancelButtonTitle:nil otherButtonTitles:@"확인", nil];
        [alertView show];
    }];
}

- (BOOL)canComment {
    return [_response rangeOfString:@"<div class=\"reply_write\">"].location != NSNotFound;
}

- (void)showActions:(id)sender {
    NSArray* items = @[_URL.absoluteURL];
    OpenInSafariActivity* openInSafari = [[OpenInSafariActivity alloc] init];
    UIActivityViewController* vc = [[UIActivityViewController alloc] initWithActivityItems:items applicationActivities:@[openInSafari]];
    [self presentViewController:vc animated:YES completion:NULL];
}

- (void)deleteArticle {
    NSString* path = [_response substringFrom:@"javascript:del('" to:@"'"];
    AFHTTPClient* client = [AFHTTPClient clientWithBaseURL:_URL];
    [client getPath:path parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString* responseString = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        NSLog(@"%@", responseString);
        // fixme check error
        [self.navigationController popViewControllerAnimated:YES];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@", error);
        // fixme
        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:nil message:error.localizedDescription delegate:nil cancelButtonTitle:nil otherButtonTitles:@"확인", nil];
        [alertView show];
    }];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [self presentComposeViewControllerWithBlock:^(ComposeViewController *vc) {
        vc.url = [NSURL URLWithString:@"./write_update.php" relativeToURL:_URL];
        vc.successBlock = ^{
            [self dismissViewControllerAnimated:YES completion:NULL];
            [self reload];
        };
//        NSString* url = [response substringFrom:@"view_content_btn\">\n          	  <a href=\"" to:@"\""];
//        NSURL* baseURL = [NSURL URLWithString:url relativeToURL:_URL];
//        [[AFHTTPClient clientWithBaseURL:baseURL] getPath:@"" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
//            NSString* response = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
////                    NSLog(@"%@", response);
//        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
//            NSLog(@"%@", error);
//        }];
        vc.loadBlock = ^(ComposeViewController* vc) {
            vc.titleField.text = [_webView stringByEvaluatingJavaScriptFromString:@"document.getElementsByClassName('view_title')[0].getElementsByTagName('span')[0].textContent"];
            vc.textView.text = [_webView stringByEvaluatingJavaScriptFromString:@"document.getElementById('writeContents').textContent"];
            NSString* attachments = [_webView stringByEvaluatingJavaScriptFromString:@"var a = document.getElementsByClassName('attachedImage'); var x = []; for (var i = 0; i < a.length; ++i) { x.push(a[i].getElementsByTagName('img')[0].src); } x.join();"];
            vc.attachments = [attachments componentsSeparatedByString:@","];
            NSString* links = [_webView stringByEvaluatingJavaScriptFromString:@"(function() { var a = document.getElementsByClassName('view_content')[0].getElementsByTagName('img'); console.log(a.length); var x = []; for (var i = 0; i < a.length; ++i) { if (a[i].src.match(/icon_link.gif$/)) { var t = a[i]; while (t.tagName != 'A') { t = t.nextSibling; console.log(t); } x.push(t.textContent.split(' ')[0]); } } return x.join(); })()"];
            NSLog(@"%@", links);
            NSArray* array = [links componentsSeparatedByString:@","];
            for (int i = 0; i < array.count; ++i) {
                ((UITextField*) vc.linkFields[i]).text = array[i];
            }
        };
        vc.title = @"글수정";
        vc.extraParameters = @{@"w": @"u"};
    }];
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
        // can be slow
        while ([webView_ stringByEvaluatingJavaScriptFromString:@"console._logs.length"].intValue > 0) {
            NSLog(@"%s: %@", __func__, [webView_ stringByEvaluatingJavaScriptFromString:@"console._logs.shift()"]);
        }

        [self openURL:request.URL];
        return NO;
    }
    return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    NSLog(@"%s: %@", __func__, webView.request);
    // 스크랩에 필요
    if (!self.title) {
        self.title = [webView stringByEvaluatingJavaScriptFromString:@"document.getElementsByClassName('view_title')[0].getElementsByTagName('span')[0].textContent"];
    }
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

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationController.toolbarHidden = NO;
    // fixme plugin?
    UIMenuItem* brickItem = [[UIMenuItem alloc] initWithTitle:@"레고 가격" action:NSSelectorFromString(@"xxx")];
    [UIMenuController sharedMenuController].menuItems = @[brickItem];
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    // fixme
    if (action == NSSelectorFromString(@"xxx")) {
        NSString* script = [NSString stringWithFormat:@"openClienCan%@();", NSStringFromSelector(action)];
        NSString* result = [_webView stringByEvaluatingJavaScriptFromString:script];
        return [result isEqualToString:@"true"];
    }
    return [super canPerformAction:action withSender:sender];
}

- (NSMethodSignature*)methodSignatureForSelector:(SEL)aSelector {
    if (aSelector == NSSelectorFromString(@"xxx")) {
        return [super methodSignatureForSelector:@selector(callJavaScriptFunction:)];
    }
    return [super methodSignatureForSelector:aSelector];
}

- (void)callJavaScriptFunction:(NSString*)function {
    NSString* script = [NSString stringWithFormat:@"openClien%@();", function];
    [_webView stringByEvaluatingJavaScriptFromString:script];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    if (anInvocation.selector == NSSelectorFromString(@"xxx")) {
        [self callJavaScriptFunction:NSStringFromSelector(anInvocation.selector)];
        return;
    }
    [super forwardInvocation:anInvocation];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    self.navigationController.toolbarHidden = YES;
    [UIMenuController sharedMenuController].menuItems = nil;
}

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
    NSLog(@"%s: %ld %@", __func__, (long)httpResponse.statusCode, httpResponse.allHeaderFields);
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [receivedData appendData:data];
    NSLog(@"%s: %lu", __func__, (unsigned long)data.length);
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSLog(@"%s: %@", __func__, error);
    connection = nil;
    [_refreshControl endRefreshing];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    connection = nil;
    _response = [[NSString alloc] initWithData:receivedData encoding:NSUTF8StringEncoding];
    if (!_response) {
        NSLog(@"invalid encoding");
        iconv_t cd = iconv_open("UTF-16", "UTF-8");
        if (cd != (iconv_t) -1) {
            NSMutableData* data = [NSMutableData dataWithLength:2 * receivedData.length];
            const char* inbuf = [receivedData bytes];
            size_t inbytesleft = receivedData.length;
            char* outbuf = [data mutableBytes];
            size_t outbytesleft = data.length;
            long x = -1;
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
            _response = [[NSString alloc] initWithData:data encoding:NSUTF16StringEncoding];
            if (x >= 0) {
                NSRange range;
                range.location = MAX(x - 500, 0);
                range.length = MIN(1000, _response.length - range.location);
                NSLog(@"x=%ld %@", x, [_response substringWithRange:range]);
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

    NSString* content = [_response substringFrom:@"<div class=\"board_main\">" to:@"<!-- 광고 영역 -->"];
    if (content) {
        NSRange range = [content rangeOfString:@"<ul class=\"view_content_btn2\""];
        if (range.location != NSNotFound) {
            content = [content substringToIndex:range.location];
        }
        [html appendString:content];
    } else {
        NSLog(@"%s: no content", __func__);
        [self showLoginAlertViewWithResponse:_response];
        return;
    }
    
    NSString* comments = [_response substringFrom:@"<div class=\"reply_head\"" to:@"<script"];
    if (comments) {
        [html appendString:@"<hr />"];
        [html appendString:@"<div class=\"reply_head\""];
        [html appendString:comments];
    } else {
        NSLog(@"%s: comments not found", __func__);
    }
    
//    NSUInteger n;
//    n = [html replaceOccurrencesOfString:@"<iframe" withString:@"<if" options:0 range:NSMakeRange(0, html.length)];
//    NSLog(@"replaced %u iframes", n);
//    NSLog(@"%s: %@", __func__, html);
    [_webView loadHTMLString:html baseURL:_URL];
    
    [_refreshControl endRefreshing];
    
    if ([_response rangeOfString:@"title=\"수정\""].length) {
        self.navigationItem.rightBarButtonItem = self.editButtonItem;
    }
    
    [self updateToolbarItems];
}

- (void)updateToolbarItems {
    UIBarButtonItem* comment = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemReply target:self action:@selector(compose:)];
    UIBarButtonItem* actions = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(showActions:)];
    UIBarButtonItem* scrap = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(scrap:)];
    UIBarButtonItem* flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:NULL];
    UIBarButtonItem* trash = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(confirmDeleteArticle:)];
    if ([_response rangeOfString:@"title=\"삭제\""].length) {
        self.toolbarItems = @[comment, flexibleSpace, scrap, flexibleSpace, actions, flexibleSpace, trash];
    } else {
        self.toolbarItems = @[comment, flexibleSpace, scrap, flexibleSpace, actions];
    }
}

- (void)showLoginAlertViewWithResponse:(NSString*)responseString {
    NSString* content = [responseString substringFrom:@"javascript'>alert('" to:@"'"];
    NSLog(@"%@", content);
    content = [content stringByReplacingOccurrencesOfString:@"\\n" withString:@" "];
    [self showLoginAlertViewWithMessage:content];
}

- (void)showLoginAlertViewWithMessage:(NSString *)message {
    [self showLoginAlertViewWithMessage:message completionBlock:^(BOOL canceled, NSString *message) {
        if (canceled) {
            if (!_webView.request) {
                [self.navigationController popViewControllerAnimated:YES];
            }
        } else {
            if (message) {
                [self showLoginAlertViewWithMessage:message];
            } else {
                [self reload];
            }
        }
    }];
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
