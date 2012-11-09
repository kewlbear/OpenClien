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
    
    [self setTitleView];
    [self setGestureRecognizer];
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
    article = [[Article alloc] init];
    NSMutableArray* content = [NSMutableArray array];
    NSMutableString* paragraph = [NSMutableString string];
    NSScanner* scanner = [NSScanner scannerWithString:[response substringFrom:@"<div id=\"resContents\"" to:@"<!-- 서명"]];
    NSLog(@"%s: %@", __func__, scanner.string);
    [scanner skip:@"<"];
    if ([scanner scanString:@"div class=\"attachedImage\">" intoString:NULL]) {
        while ([scanner scanString:@"<img" intoString:NULL]) {
            [scanner skip:@"src="];
            NSString* quote;
            [scanner scanCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"\"'"] intoString:&quote];
            NSString* src;
            [scanner scanUpToString:quote intoString:&src];
            [content addObject:[[ImageParagraph alloc] initWithURL:[NSURL URLWithString:[src stringByReplacingOccurrencesOfString:@"../" withString:@"http://clien.career.co.kr/cs2/"]]]];
            NSLog(@"%s: attach %@", __func__, src);
        }
    }
    [scanner skip:@"span id=\"writeContents\""];
    [scanner skip:@">"];
    while (!scanner.isAtEnd) {
        NSString* string;
        [scanner scanUpToString:@"<" intoString:&string];
        if ([scanner scanString:@"<" intoString:NULL]) {
            if (string) {
                [paragraph appendString:string];
            }
            NSLog(@"%s: %@", __func__, string);
            if ([scanner scanString:@"!--" intoString:NULL]) {
                [scanner skip:@"-->"];
                NSLog(@"%s: HTML comment", __func__);
            } else if ([scanner scanString:@"br />" intoString:NULL]) {
                [paragraph appendString:@"\n"];
                NSLog(@"%s: br", __func__);
            } else if ([scanner scanString:@"p>" intoString:NULL]) {
                [content addObject:[[TextParagraph alloc] initWithString:paragraph]];
                paragraph = [NSMutableString string];
                NSLog(@"%s: p", __func__);
            } else if ([scanner scanString:@"a href=\"" intoString:NULL]) {
                NSString* href;
                [scanner scanUpToString:@"\"" intoString:&href];
                [scanner skip:@">"];
                [scanner scanUpToString:@"<" intoString:&string];
                [paragraph appendFormat:@"%@:%@", href, string];
                [scanner skip:@">"];
                NSLog(@"%s: a %@ %@", __func__, href, string);
            } else if ([scanner scanString:@"img" intoString:NULL]) {
                [scanner skip:@"src=\""];
                NSString* src;
                [scanner scanUpToString:@"\"" intoString:&src];
                [scanner skip:@">"];
                [content addObject:[[TextParagraph alloc] initWithString:paragraph]];
                paragraph = [NSMutableString string];
                [content addObject:[[ImageParagraph alloc] initWithURL:[NSURL URLWithString:src]]];
                NSLog(@"%s: img %@", __func__, src);
            } else if ([scanner scanString:@"object" intoString:NULL]) {
                [content addObject:[[TextParagraph alloc] initWithString:paragraph]];
                paragraph = [NSMutableString string];
                [content addObject:[[TextParagraph alloc] initWithString:@"<object>"]];
                [scanner skip:@"</object>"];
                NSLog(@"%s: object", __func__);
            } else if ([scanner scanString:@"embed" intoString:NULL]) {
                [content addObject:[[TextParagraph alloc] initWithString:paragraph]];
                paragraph = [NSMutableString string];
                [content addObject:[[TextParagraph alloc] initWithString:@"<embed>"]];
                [scanner skip:@"</embed>"];
                NSLog(@"%s: object", __func__);
            } else {
                while ([scanner scanUpToString:@">" intoString:&string]) {
                    NSLog(@"%s: %@>", __func__, string);
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
        } else {
            [paragraph appendString:string];
            [content addObject:[[TextParagraph alloc] initWithString:paragraph]];
            paragraph = [NSMutableString string];
            NSLog(@"%s: %@", __func__, string);
        }
    }
    if ([paragraph length]) {
        [content addObject:[[TextParagraph alloc] initWithString:paragraph]];
    }
    NSLog(@"%s: %@", __func__, content);
    article.content = content;
    NSLog(@"%s: 본문 스캔 끝", __func__);
    NSMutableArray* array = [NSMutableArray array];
    scanner = [NSScanner scannerWithString:[response substringFrom:@"<div id=\"comment_wrapper\">" to:@"<script"]];
    NSLog(@"%s: %@", __func__, scanner.string);
    while (!scanner.isAtEnd) {
        Comment* comment = [[Comment alloc] init];
        [scanner skip:@"<li class=\"user_id\">"];
        NSString* user = nil;
        while ([scanner scanString:@"<img" intoString:NULL]) {
            [scanner skip:@"src="];
            NSString* quote;
            [scanner scanCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"\"'"] intoString:&quote];
            [scanner scanUpToString:quote intoString:&user];
//            NSLog(@"%s: quote=%@ %@", __func__, quote, user);
            if ([user rangeOfString:@"/blet_re2.gif"].location != NSNotFound) {
                comment.nested = YES;
            }
            [scanner skip:@">"];
        }
        if (user && [user rangeOfString:@"/member/"].location != NSNotFound) {
            user = [[NSURL URLWithString:user relativeToURL:_URL] absoluteString];
        } else {
            [scanner skip:@">"];
            [scanner scanUpToString:@"</span>" intoString:&user];
        }
        NSLog(@"%s: user=%@", __func__, user);
        if (!user) {
            break;
        }
        comment.user = user;
        [scanner skip:@"<li> ("];
        NSString* timestamp;
        [scanner scanUpToString:@")" intoString:&timestamp];
        comment.timestamp = timestamp;
        [scanner skip:@"<div class=\"reply_content\">"];
        NSString* content;
        [scanner scanUpToString:@"<span" intoString:&content];
        content = [content stringByReplacingOccurrencesOfString:@"<br/>" withString:@"\n"];
        comment.content = content.gtm_stringByUnescapingFromHTML;
        [array addObject:comment];
    }
    comments = array;
    [self.tableView reloadData];
    
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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 1;
    } else {
        return [comments count];
    }
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        ArticleCell* cell = [[ArticleCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
        [cell setArticle:article];
        return cell;
    } else {
        static NSString* CellIdentifier = @"comment cell";
        CommentCell* cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (!cell) {
            cell = [[CommentCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        }
        Comment* comment = [comments objectAtIndex:indexPath.row];
        cell.textLabel.text = comment.content;
        if ([comment.user rangeOfString:@"http://"].location == 0) {
            [cell.imageView setImageWithURL:[NSURL URLWithString:comment.user] placeholderImage:[[UIImage alloc] init]];
        } else {
            cell.detailTextLabel.text = comment.user;
        }
        if (comment.nested) {
            cell.indentationLevel = 1;
        }
        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat height;
    if (indexPath.section == 0) {
        height = [ArticleCell heightForArticle:article tableView:tableView];
    } else {
        Comment* comment = [comments objectAtIndex:indexPath.row];
        height = [CommentCell heightForComment:comment tableView:tableView];
    }
    if (height < 44) {
        height = 44;
    }
    return height;
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
