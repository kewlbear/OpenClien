//
//  BoardViewController.m
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
#import "SettingsViewController.h"
#import "UIViewController+URL.h"

@interface BoardViewController () {
    UIView* view;
    BOOL isLoading;
    BOOL isLoadingMore;
    int page;
    UIActivityIndicatorView* indicator;
    NSString* responseString;
    NSString* lastArticleId;
    UISearchDisplayController* _searchDisplayController;
    NSMutableArray* _searchResults;
    UIPopoverController* _popover;
    BOOL shouldLoadMore;
}

@end

@implementation BoardViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(compose:)];
        UIBarButtonItem* searchItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(activateSearch:)];
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            UIButton* infoButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
            [infoButton addTarget:self action:@selector(openSettings:) forControlEvents:UIControlEventTouchUpInside];
            infoButton.frame = UIEdgeInsetsInsetRect(infoButton.frame, UIEdgeInsetsMake(0, -10, 0, -10));
            UIBarButtonItem* settingsItem = [[UIBarButtonItem alloc] initWithCustomView:infoButton];
            self.toolbarItems = @[settingsItem, searchItem];
        } else {
            self.toolbarItems = @[searchItem];
        }
    }
    return self;
}

- (IBAction)openSettings:(id)sender {
    SettingsViewController* vc = [[SettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
    UINavigationController* nc = [[UINavigationController alloc] initWithRootViewController:vc];
    _popover = [[UIPopoverController alloc] initWithContentViewController:nc];
    [_popover presentPopoverFromBarButtonItem:self.toolbarItems[0] permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

- (void)activateSearch:(id)sender {
    // fixme save current content offset?
    [self.tableView scrollRectToVisible:_searchDisplayController.searchBar.frame animated:NO]; // iOS 7
    [_searchDisplayController setActive:YES animated:YES];
}

- (void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller {
    [controller.searchBar becomeFirstResponder];
}

- (void)searchDisplayControllerDidEndSearch:(UISearchDisplayController *)controller {
    // fixme restore saved content offset?
    [self.tableView setContentOffset:CGPointMake(0, controller.searchBar.bounds.size.height) animated:YES];
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    return NO;
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption {
    [self reload];
    return NO;
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [self reload];
}

- (void)compose:(id)sender {
    if ([self canWrite]) {
        [self presentComposeViewControllerWithBlock:^(ComposeViewController *vc) {
            vc.url = [NSURL URLWithString:@"./write_update.php" relativeToURL:_URL];
            vc.successBlock = ^{
                [self dismissViewControllerAnimated:YES completion:NULL];
                [self reload];
            };
            NSString* url = [responseString substringFrom:@"write_button\">\n	<a href=\"" to:@"\""];
            NSURL* baseURL = [NSURL URLWithString:url relativeToURL:_URL];
            [[AFHTTPClient clientWithBaseURL:baseURL] getPath:@"" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
                NSString* response = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
                //                    NSLog(@"%@", response);
                NSString* options = [response substringFrom:@"<option value=\"\">선택하세요" to:@"\n</select>"];
                if (options) {
                    NSArray* array = [options componentsSeparatedByString:@"\n"];
                    NSMutableArray* categories = [NSMutableArray array];
                    [array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                        [categories addObject:[obj substringFrom:@"'" to:@"'"]];
                    }];
                    vc.categories = categories;
                } else {
                    NSString* message = [response substringFrom:@"'javascript'>alert('" to:@"');"];
                    if (message) {
                        [self dismissViewControllerAnimated:NO completion:^{
                            UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:nil message:message delegate:nil cancelButtonTitle:nil otherButtonTitles:@"확인", nil];
                            [alertView show];
                        }];
                    }
                }
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                NSLog(@"%@", error);
                // fixme
            }];
            vc.title = @"글쓰기";
        }];
    } else {
        // fixme other restrictions?
        [self showLoginAlertViewWithMessage:@"로그인이 필요한 기능입니다." completionBlock:NULL];
    }
}

- (BOOL)canWrite {
    return [responseString rangeOfString:@"<a href=\"./write.php?"].length;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    BOOL isSearchResults = [_URL.query rangeOfString:@"stx="].length;
    if (isSearchResults) {
        self.navigationItem.rightBarButtonItem = nil;
        self.toolbarItems = nil; // fixme
    }
    
    if (!isSearchResults && !_searchDisplayController) {
        UISearchBar* searchBar = [[UISearchBar alloc] init];
        searchBar.delegate = self;
        searchBar.scopeButtonTitles = @[@"제목", @"내용", @"제+내", @"ID", @"ID/코", @"이름", @"이름/코"];
        [searchBar sizeToFit];
        self.tableView.tableHeaderView = searchBar;
        _searchDisplayController = [[UISearchDisplayController alloc] initWithSearchBar:searchBar contentsController:self];
        _searchDisplayController.delegate = self;
        _searchDisplayController.searchResultsDataSource = self;
        _searchDisplayController.searchResultsDelegate = self;
        _searchResults = [NSMutableArray array];
    }
    
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
    if (self.searchDisplayController.active || (more && [_URL.query rangeOfString:@"stx="].length)) {
        if (more) {
            NSString* x = [responseString substringFrom:@"<div class=\"paging\">" to:@"*다음검색*"];
            NSRange range = [x rangeOfString:@"<a class='cur_page'>"];
            if (range.length) {
                x = [x substringFromIndex:range.location + range.length];
            } else {
                range = [x rangeOfString:@"*이전검색*"];
                if (range.length) {
                    x = [x substringFromIndex:range.location + range.length];
                }
                // 다음검색은 1페이지에서 시작
                x = [x stringByReplacingOccurrencesOfString:@"page=" withString:@"xxx="];
            }
            x = [x substringFrom:@" href='" to:@"'"];
            URL = [NSURL URLWithString:x relativeToURL:_URL];
        } else {
            NSString* stx = self.searchDisplayController.searchBar.text.precomposedStringWithCanonicalMapping;
            stx = [stx stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            NSArray* sfls = @[@"wr_subject", @"wr_content", @"wr_subject||wr_content", @"mb_id,1", @"mb_id,0", @"wr_name,1", @"wr_name,0"];
            NSString* sfl = [sfls[_searchDisplayController.searchBar.selectedScopeButtonIndex] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            URL = [NSURL URLWithString:[_URL.absoluteString stringByAppendingFormat:@"&sca=&sfl=%@&stx=%@", sfl, stx]];
        }
    } else {
        if (more) {
            URL = [NSURL URLWithString:[_URL.absoluteString stringByAppendingFormat:@"&page=%d", page + 1]];
        } else {
            page = 1;
            URL = _URL;
        }
    }
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:URL];
    if (self.searchDisplayController.active || [_URL.query rangeOfString:@"&stx="].length /* fixme */) {
        [request addValue:_URL.absoluteString forHTTPHeaderField:@"Referer"];
    }
    [[[AFHTTPClient clientWithBaseURL:URL] HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (isLoadingMore) {
            ++page;
        }
        responseString = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        // fixme
        if ([_URL.query rangeOfString:@"bo_table=image"].location == NSNotFound) {
            [self parseNonImage];
        } else {
            [self parseImage];
        }
//        responseString = nil;
        
        // fixme only do when needed
        AppDelegate* appDelegate = (AppDelegate*) [UIApplication sharedApplication].delegate;
        [appDelegate.popoverController dismissPopoverAnimated:YES];
        shouldLoadMore = YES;
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%s: %@", __func__, error);
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:operation.request.URL.description message:error.localizedDescription delegate:nil cancelButtonTitle:nil otherButtonTitles:@"확인", nil];
        [alert show];
        [self setRefreshButton];
        shouldLoadMore = NO;
    }] start];
}

- (void)setRefreshButton {
    isLoading = NO;
    [indicator stopAnimating];
    [self.refreshControl endRefreshing];
    if (!isLoadingMore && !_searchDisplayController.active) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
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
        [scanner skip:@"<tr"];
        // 공지사항
        BOOL isNotice = [scanner scanString:@"class=\"post_notice\"" intoString:NULL];
        [scanner skip:@"<td"];
        // 체험단 사용기 광고
        if (![scanner scanString:@">" intoString:NULL]) {
            continue;
        }
        NSString* articleId;
        if (!isNotice && ![scanner scanUpToString:@"<" intoString:&articleId]) {
            break;
        }
        if (isLoadingMore && !_searchDisplayController.active && [articleId compare:lastArticleId] != NSOrderedAscending) {
            ++overlapCount;
            continue;
        }
        article.ID = articleId;
        [scanner skip:@"class=\"post_subject\">"];
        NSString* title;
        if ([scanner scanString:@"<span " intoString:NULL]) {
            [scanner skip:@"'>"];
            [scanner scanUpToString:@"</span>" intoString:&title];
        } else {
            [scanner skip:@"href='"];
            NSString* href;
            [scanner scanUpToString:@"'" intoString:&href];
            article.URL = [NSURL URLWithString:href relativeToURL:_URL];
            [scanner skip:@">"];
            [scanner scanUpToString:@"</a>" intoString:&title];
        }
        if (self.searchDisplayController.active) {
            // fixme use attributed string
            title = [title stringByReplacingOccurrencesOfString:@"<span class='search_text'>" withString:@""];
            title = [title stringByReplacingOccurrencesOfString:@"</span>" withString:@""];
        }
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
        if (isLoadingMore) {
            [_searchResults addObjectsFromArray:array];
        } else {
            _searchResults = array;
        }
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
        if ([scanner scanString:@"<a href=\"javascript:;\"" intoString:NULL]) {
            [scanner skip:@">"];
        }
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
    if (article.URL) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
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
    if (article.URL) {
        ArticleViewController* controller = [[ArticleViewController alloc] initWithNibName:nil bundle:nil];
        controller.URL = article.URL;
        controller.title = article.title;
        [self push:controller];
    } else {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
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
    NSArray* array;
    if (scrollView == self.tableView) {
        array = articles;
    } else {
        array = _searchResults;
    }
    CGFloat height = scrollView.contentSize.height;
    if (shouldLoadMore && !isLoading && array.count && height - scrollView.contentOffset.y - scrollView.bounds.size.height < 0) {
        NSLog(@"%s: content height=%f offset=%f view height=%f", __func__, height, scrollView.contentOffset.y, scrollView.bounds.size.height);
        [self loadMore:YES];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    shouldLoadMore = YES;
}

@end
