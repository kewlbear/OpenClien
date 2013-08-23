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
#import "SDWebImage/UIImageView+WebCache.h"
#import "BoardCell.h"
#import "GTMNSString+HTML.h"
#import "UIViewController+Stack.h"
#import "AFHTTPClient.h"
#import "AppDelegate.h"
#import "ComposeViewController.h"
#import "AFNetworking.h"

@interface BoardViewController () {
    UIView* view;
    BOOL isLoading;
    BOOL isLoadingMore;
    int page;
    UIActivityIndicatorView* indicator;
    NSString* responseString;
    NSString* lastArticleId;
    UISearchDisplayController* _searchDisplayController;
    NSArray* _searchResults;
}

@end

@implementation BoardViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(compose:)];
        UIBarButtonItem* searchItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(activateSearch:)];
        self.toolbarItems = @[searchItem];
    }
    return self;
}

- (void)activateSearch:(id)sender {
    if (!_searchDisplayController) {
        UISearchBar* searchBar = [[UISearchBar alloc] init];
        searchBar.delegate = self;
        searchBar.scopeButtonTitles = @[@"a", @"b"];
        _searchDisplayController = [[UISearchDisplayController alloc] initWithSearchBar:searchBar contentsController:self];
        _searchDisplayController.delegate = self;
        _searchDisplayController.searchResultsDataSource = self;
        _searchDisplayController.searchResultsDelegate = self;
        _searchResults = [NSMutableArray array];
    }
    [_searchDisplayController setActive:YES animated:YES];
}

- (void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller {
    [self.view addSubview:controller.searchBar];
    [controller.searchBar becomeFirstResponder];
}

- (void)searchDisplayControllerWillEndSearch:(UISearchDisplayController *)controller {
    [controller.searchBar removeFromSuperview];
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    return NO;
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption {
    return NO;
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [self reload];
}

- (void)compose:(id)sender {
    NSString* identifier;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        identifier = @"Compose";
    } else {
        identifier = @"ComposePad";
    }
    ComposeViewController* vc = [[UIStoryboard storyboardWithName:@"SharedStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:identifier];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        self.navigationController.modalPresentationStyle = UIModalPresentationCurrentContext;
    } else {
        vc.modalPresentationStyle = UIModalPresentationFormSheet;
    }
    [self presentViewController:vc animated:YES completion:NULL];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        vc.view.superview.bounds = CGRectMake(0, 0, 300, 225);
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(reload) forControlEvents:UIControlEventValueChanged];
    
    if (!indicator) {
        indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        indicator.frame = CGRectMake(0, 0, self.tableView.rowHeight, self.tableView.rowHeight);
    }
    self.tableView.tableFooterView = indicator;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [self setGestureRecognizer];
    }
    
    [self loadMore:NO];
}

- (void)loadMore:(BOOL)more {
    if (isLoading) {
        return;
    }
    isLoadingMore = more;
    [indicator startAnimating];
    isLoading = YES;

    NSURL* URL;
    if (self.searchDisplayController.active) {
        NSString* stx = self.searchDisplayController.searchBar.text.precomposedStringWithCanonicalMapping;
        stx = [stx stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        URL = [NSURL URLWithString:[_URL.absoluteString stringByAppendingFormat:@"&sca=&sfl=wr_subject&stx=%@", stx]];
    } else {
        if (more) {
            URL = [NSURL URLWithString:[_URL.absoluteString stringByAppendingFormat:@"&page=%d", page + 1]];
        } else {
            page = 1;
            URL = _URL;
        }
    }
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:URL];
    if (self.searchDisplayController.active) {
        [request addValue:_URL.absoluteString forHTTPHeaderField:@"Referer"];
    }
    [[[AFHTTPClient clientWithBaseURL:URL] HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (isLoadingMore) {
            ++page;
        }
        responseString = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        if ([_URL.query rangeOfString:@"bo_table=image"].location == NSNotFound) {
            [self parseNonImage];
        } else {
            [self parseImage];
        }
        responseString = nil;
        
        // fixme only do when needed
        AppDelegate* appDelegate = (AppDelegate*) [UIApplication sharedApplication].delegate;
        [appDelegate.popoverController dismissPopoverAnimated:YES];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%s: %@", __func__, error);
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:operation.request.URL.description message:error.localizedDescription delegate:nil cancelButtonTitle:nil otherButtonTitles:@"확인", nil];
        [alert show];
        [self setRefreshButton];
    }] start];
}

- (void)setRefreshButton {
    isLoading = NO;
//    self.navigationItem.rightBarButtonItem.enabled = YES;
    [indicator stopAnimating];
    [self.refreshControl endRefreshing];
}

- (void)reload {
    [self loadMore:NO];
}

- (void)parseNonImage {
    NSScanner* scanner = [NSScanner scannerWithString:[responseString substringFrom:@"<form name=\"fboardlist\"" to:@"</tbody>"]];
//    NSLog(@"%s: %@", __func__, scanner.string);
    NSMutableArray* array = [NSMutableArray array];
    int overlapCount = 0;
    while (!scanner.isAtEnd) {
        Article* article = [[Article alloc] init];
        [scanner skip:@"<tr class=\"mytr\">"];
        [scanner skip:@"<td>"];
        NSString* articleId;
        if (![scanner scanUpToString:@"<" intoString:&articleId]) {
            break;
        }
        if (isLoadingMore && [articleId compare:lastArticleId] != NSOrderedAscending) {
            ++overlapCount;
            continue;
        }
        article.ID = articleId;
        [scanner skip:@"<td class=\"post_subject\">"];
        [scanner skip:@"href='"];
        NSString* href;
        [scanner scanUpToString:@"'" intoString:&href];
        article.URL = [NSURL URLWithString:href relativeToURL:_URL];
        [scanner skip:@">"];
        NSString* title;
        [scanner scanUpToString:@"</a>" intoString:&title];
        if (self.searchDisplayController.active) {
            // fixme use attributed string
            title = [title stringByReplacingOccurrencesOfString:@"<span class='search_text'>" withString:@""];
            title = [title stringByReplacingOccurrencesOfString:@"</span>" withString:@""];
        }
        NSLog(@"%@", title);
        article.title = title.gtm_stringByUnescapingFromHTML;
        [scanner skip:@"</a>"];
        if ([scanner scanString:@"<span>[" intoString:NULL]) {
            int numberOfComments;
            [scanner scanInt:&numberOfComments];
            article.numberOfComments = numberOfComments;
        }
        [scanner skip:@"<td class=\"post_name"];
        [scanner skip:@">"];
        if ([scanner scanString:@"<a " intoString:NULL]) {
            [scanner skip:@">"];
        }
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
//        NSLog(@"%s: %@ %@", __func__, articleId, title);
    }
    NSLog(@"%d overlaps", overlapCount);
    if (self.searchDisplayController.active) {
        // fixme more results
        _searchResults = array;
        [self.searchDisplayController.searchResultsTableView reloadData];
    } else {
        if (isLoadingMore) {
            [articles addObjectsFromArray:array];
        } else {
            articles = array;
        }
        Article* lastArticle = [array lastObject];
        lastArticleId = lastArticle.ID;
        [self.tableView reloadData];
    }
    [self setRefreshButton];
}

- (void)parseImage {
    NSScanner* scanner = [NSScanner scannerWithString:[responseString substringFrom:@"<form name=\"fboardlist\"" to:@"</tbody>"]];
    NSLog(@"%s: %@", __func__, scanner.string);
    NSMutableArray* array;
    if (isLoadingMore) {
        array = [articles mutableCopy];
    } else {
        array = [NSMutableArray array];
    }
    while (!scanner.isAtEnd) {
        Article* article = [[Article alloc] init];
        [scanner skip:@"<p class=\"user_info"];
        [scanner skip:@">"];
        NSString* name;
        if ([scanner scanString:@"<span class='member'>" intoString:NULL]) {
            [scanner scanUpToString:@"</span>" intoString:&name];
        } else {
            [scanner skip:@"src="];
            NSString* quote;
            if ([scanner scanCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"\"'"] intoString:&quote]) {
                [scanner scanUpToString:quote intoString:&name];
                name = [[NSURL URLWithString:name relativeToURL:_URL] absoluteString];
            }
        }
        if (!name) {
            break;
        }
        NSLog(@"%s: name=%@", __func__, name);
        article.name = name;
        [scanner skip:@"<p class=\"post_info\">"];
        NSString* postInfo;
        [scanner scanUpToString:@"</p>" intoString:&postInfo];
        NSLog(@"%s: post_info=%@", __func__, postInfo);
        [scanner skip:@"<h4>"];
        [scanner skip:@"href="];
        NSString* quote;
        [scanner scanCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"\"'"] intoString:&quote];
        NSLog(@"%s: quote=%@", __func__, quote);
        NSString* href;
        [scanner scanUpToString:quote intoString:&href];
        NSLog(@"%s: href=%@", __func__, href);
        article.URL = [NSURL URLWithString:href relativeToURL:_URL];
        [scanner skip:@">"];
        NSString* title;
        [scanner scanUpToString:@"<" intoString:&title];
        NSLog(@"%s: title=%@", __func__, title);
        article.title = title.gtm_stringByUnescapingFromHTML;
        [scanner skip:@"src=\""];
        NSString* src;
        [scanner scanUpToString:@"\"" intoString:&src];
        NSLog(@"%s: src=%@", __func__, src);
        [scanner skip:@"span id=\"writeContents\""];
        [scanner skip:@">"];
        NSString* content;
        [scanner scanUpToString:@"</span>" intoString:&content];
        NSLog(@"%s: content=%@", __func__, content);
        [array addObject:article];
        //        NSLog(@"%s: %@ %@", __func__, href, title);
    }
    articles = array;
    [self.tableView reloadData];
    [self setRefreshButton];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        return [articles count];
    } else {
        return _searchResults.count;
    }
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString* CellIdentifier = @"board cell";
    BoardCell* cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[BoardCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    Article* article;
    if (tableView == self.tableView) {
        article = articles[indexPath.row];
    } else {
        article = _searchResults[indexPath.row];
    }
    cell.textLabel.text = article.title;
    if ([article.name rangeOfString:@"http://"].location == 0) {
        [cell.imageView setImageWithURL:[NSURL URLWithString:article.name] placeholderImage:[[UIImage alloc] init] options:0];
    } else {
        cell.detailTextLabel.text = article.name;
    }
//    cell.detailTextLabel.text = [cell.detailTextLabel.text stringByAppendingFormat:@" 댓글: %d %@ %d hits", article.numberOfComments, article.timestamp, article.numberOfHits];
    cell.numberOfComments = article.numberOfComments;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Article* article;
    if (tableView == self.tableView) {
        article = articles[indexPath.row];
    } else {
        article = _searchResults[indexPath.row];
    }
    NSLog(@"%s: %@", __func__, article.URL);
    ArticleViewController* controller = [[ArticleViewController alloc] initWithNibName:nil bundle:nil];
    controller.URL = article.URL;
    controller.title = article.title;
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
