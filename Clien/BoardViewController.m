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
#import "UIImageView+AFNetworking.h"
#import "BoardCell.h"
#import "GTMNSString+HTML.h"
#import "UIViewController+Stack.h"

@interface BoardViewController () {
    UIView* view;
    BOOL isLoading;
    BOOL isLoadingMore;
    int page;
    UIActivityIndicatorView* indicator;
}

@end

@implementation BoardViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    if (!indicator) {
        indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        indicator.frame = CGRectMake(0, 0, self.view.frame.size.width, 44);
    }
    self.tableView.tableFooterView = indicator;
    
    [self setGestureRecognizer];
    
    [self loadMore:NO];
}

- (void)loadMore:(BOOL)more {
    if (isLoading) {
        return;
    }
    isLoadingMore = more;
    [indicator startAnimating];
    NSURL* URL;
    if (more) {
        URL = [NSURL URLWithString:[_URL.absoluteString stringByAppendingFormat:@"&page=%d", page + 1]];
    } else {
        page = 1;
        URL = _URL;
    }
    NSURLRequest* request = [NSURLRequest requestWithURL:URL];
    NSURLConnection* connection = [NSURLConnection connectionWithRequest:request delegate:self];
    if (connection) {
        isLoading = YES;
        receivedData = [NSMutableData data];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:indicator];
    } else {
        NSLog(@"%s: connection failed", __func__);
        [self setRefreshButton];
    }
}

- (void)setRefreshButton {
    isLoading = NO;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(reload)];
    [indicator stopAnimating];
}

- (void)reload {
    [self loadMore:NO];
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
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:connection.originalRequest.URL.description message:error.localizedDescription delegate:nil cancelButtonTitle:nil otherButtonTitles:@"확인", nil];
    [alert show];
    [self setRefreshButton];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    if (isLoadingMore) {
        ++page;
    }
    NSString* response = [[NSString alloc] initWithData:receivedData encoding:NSUTF8StringEncoding];
    NSScanner* scanner = [NSScanner scannerWithString:[response substringFrom:@"<form name=\"fboardlist\"" to:@"</tbody>"]];
    NSLog(@"%s: %@", __func__, scanner.string);
    NSMutableArray* array;
    if (isLoadingMore) {
        array = [articles mutableCopy];
    } else {
        array = [NSMutableArray array];
    }
    while (!scanner.isAtEnd) {
        Article* article = [[Article alloc] init];
        [scanner skip:@"<td class=\"post_subject\">"];
        [scanner skip:@"href='"];
        NSString* href;
        if (![scanner scanUpToString:@"'" intoString:&href]) {
            break;
        }
        article.URL = [NSURL URLWithString:href relativeToURL:_URL];
        [scanner skip:@">"];
        NSString* title;
        [scanner scanUpToString:@"<" intoString:&title];
        article.title = title.gtm_stringByUnescapingFromHTML;
        [scanner skip:@"</a>"];
        if ([scanner scanString:@"<span>[" intoString:NULL]) {
            int numberOfComments;
            [scanner scanInt:&numberOfComments];
            article.numberOfComments = numberOfComments;
        }
        [scanner skip:@"<td class=\"post_name"];
        [scanner skip:@">"];
        NSString* name;
        if ([scanner scanString:@"<span class='member'>" intoString:NULL]) {
            [scanner scanUpToString:@"</span>" intoString:&name];
        } else {
            [scanner skip:@"src='"];
            [scanner scanUpToString:@"'" intoString:&name];
            name = [[NSURL URLWithString:name relativeToURL:_URL] absoluteString];
        }
        article.name = name;
//        [scanner skip:@"<span title=\""];
//        NSString* timestamp;
//        [scanner scanUpToString:@"\">" intoString:&timestamp];
//        article.timestamp = timestamp;
//        [scanner skip:@"<td>"];
//        int numberOfHits;
//        [scanner scanInt:&numberOfHits];
//        article.numberOfHits = numberOfHits;
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
    static NSString* CellIdentifier = @"board cell";
    BoardCell* cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[BoardCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    Article* article = [articles objectAtIndex:indexPath.row];
    cell.textLabel.text = article.title;
    if ([article.name rangeOfString:@"http://"].location == 0) {
        [cell.imageView setImageWithURL:[NSURL URLWithString:article.name] placeholderImage:[[UIImage alloc] init]];
    } else {
        cell.detailTextLabel.text = article.name;
    }
//    cell.detailTextLabel.text = [cell.detailTextLabel.text stringByAppendingFormat:@" 댓글: %d %@ %d hits", article.numberOfComments, article.timestamp, article.numberOfHits];
    cell.numberOfComments = article.numberOfComments;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Article* article = [articles objectAtIndex:indexPath.row];
    NSLog(@"%s: %@", __func__, article.URL);
    ArticleViewController* controller = [[ArticleViewController alloc] initWithNibName:nil bundle:nil];
    controller.URL = article.URL;
    controller.title = article.title;
//    [self.navigationController pushViewController:controller animated:YES];
    [self push:controller];
}

- (void)viewDidUnload
{
    [self setTableView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (!isLoading && scrollView.contentSize.height - scrollView.contentOffset.y - scrollView.bounds.size.height < scrollView.contentSize.height * .1f) {
        NSLog(@"%s: content height=%f offset=%f view height=%f", __func__, scrollView.contentSize.height, scrollView.contentOffset.y, scrollView.bounds.size.height);
        [self loadMore:YES];
    }
}

@end
