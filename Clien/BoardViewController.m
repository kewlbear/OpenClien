//
//  BoardViewController.m
//  Clien
//
//  Created by 안창범 on 12. 8. 21..
//  Copyright (c) 2012년 안창범. All rights reserved.
//

#import "BoardViewController.h"
#import "NSString+SubstringFromTo.h"
#import "NSScanner+Skip.h"
#import "Article.h"
#import "ArticleViewController.h"

@interface BoardViewController ()

@end

@implementation BoardViewController

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
    
    [self reload];
}

- (void)reload {
    NSURL* URL = [NSURL URLWithString:[self.href stringByReplacingOccurrencesOfString:@"./" withString:@"http://clien.career.co.kr/"]];
    NSURLRequest* request = [NSURLRequest requestWithURL:URL];
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
    NSLog(@"%s: %d", __func__, httpResponse.statusCode);
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
    NSScanner* scanner = [NSScanner scannerWithString:[response substringFrom:@"<div class=\"board_title\">" to:@"</div>"]];
    [scanner skip:@"\">"];
    NSString* title;
    [scanner scanUpToString:@"</a>" intoString:&title];
    self.title = title;
    scanner = [NSScanner scannerWithString:[response substringFrom:@"<form name=\"fboardlist\"" to:@"</tbody>"]];
    NSLog(@"%s: %@", __func__, scanner.string);
    NSMutableArray* array = [NSMutableArray array];
    while (!scanner.isAtEnd) {
        Article* article = [[Article alloc] init];
        [scanner skip:@"<td class=\"post_subject\">"];
        [scanner skip:@"href='"];
        NSString* href;
        if (![scanner scanUpToString:@"'" intoString:&href]) {
            break;
        }
        article.href = href;
        [scanner skip:@">"];
        NSString* title;
        [scanner scanUpToString:@"<" intoString:&title];
        article.title = title;
        [scanner skip:@"</a>"];
        if ([scanner scanString:@"<span>[" intoString:NULL]) {
            int numberOfComments;
            [scanner scanInt:&numberOfComments];
            article.numberOfComments = numberOfComments;
        }
        [scanner skip:@"<td class=\"post_name\">"];
        NSString* name;
        if ([scanner scanString:@"<span class='member'>" intoString:NULL]) {
            [scanner scanUpToString:@"</span>" intoString:&name];
        } else {
            [scanner skip:@"src='"];
            [scanner scanUpToString:@"'" intoString:&name];
        }
        article.name = name;
        [scanner skip:@"<span title=\""];
        NSString* timestamp;
        [scanner scanUpToString:@"\">" intoString:&timestamp];
        article.timestamp = timestamp;
        [scanner skip:@"<td>"];
        int numberOfHits;
        [scanner scanInt:&numberOfHits];
        article.numberOfHits = numberOfHits;
        [array addObject:article];
//        NSLog(@"%s: %@ %@", __func__, href, title);
    }
    articles = array;
    [self.tableView reloadData];
    [self setRefreshButton];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [articles count];
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString* CellIdentifier = @"cell";
    UITableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    Article* article = [articles objectAtIndex:indexPath.row];
    cell.textLabel.text = article.title;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ 댓글: %d %@ %d hits", article.name, article.numberOfComments, article.timestamp, article.numberOfHits];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Article* article = [articles objectAtIndex:indexPath.row];
    NSLog(@"%s: %@", __func__, article.href);
    ArticleViewController* controller = [[ArticleViewController alloc] initWithNibName:nil bundle:nil];
    controller.href = article.href;
    [self.navigationController pushViewController:controller animated:YES];
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
