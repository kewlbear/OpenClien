//
//  OCBoardTableViewController.m
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

#import "OCBoardTableViewController.h"
#import <OpenClien/OpenClien.h>
#import "OCArticleTableViewController.h"
#import "OCBoardTableViewCell.h"
#import "OCWebViewController.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "OCComposeViewController.h"
#import "Example_copy-Swift.h"

enum {
    kCategoryActionSheetTag
};

static NSString* REUSE_IDENTIFIER = @"board cell";

@interface OCBoardTableViewController ()

@end

@implementation OCBoardTableViewController
{
    OCBoardParser *_parser;
    NSArray *_articles;
    OCBoardTableViewCell *_prototypeCell;
    UIActivityIndicatorView *_moreIndicator;
    NSArray *_searchResult;
    NSArray *_categories;
    __weak IBOutlet UIBarButtonItem *_categoryItem;
    OCBoardParser *_searchParser;
    int _searchField;
    UIBarButtonItem *_searchFieldItem;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(reload) forControlEvents:UIControlEventValueChanged];
    
    _searchFieldItem = [[UIBarButtonItem alloc] initWithTitle:@"제목" style:UIBarButtonItemStylePlain target:self action:@selector(showSearchFieldView:)];
    
    [self setupSearch];
    
    UISearchBar *searchBar = _searchController.searchBar;
    searchBar.delegate = self;
    UIToolbar *toolbar = [[UIToolbar alloc] init];
    toolbar.items = @[_searchFieldItem];
    [toolbar sizeToFit];
    searchBar.inputAccessoryView = toolbar;
    [searchBar sizeToFit];
    if (_searchController.searchResultsController != self) {
        self.tableView.tableHeaderView = searchBar;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self activeModel] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OCBoardTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:REUSE_IDENTIFIER];
//    if (!cell) {
//        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:REUSE_IDENTIFIER];
//    }

    [self configureCell:cell forRowAtIndexPath:indexPath tableView:tableView];
    
    if (indexPath.row == [[self activeModel] count] - 1) {
        [self loadMoreForce:NO];
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self configureCell:[self prototypeCell] forRowAtIndexPath:indexPath tableView:tableView];
    [[self prototypeCell] layoutIfNeeded];
    return [[self prototypeCell].contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height + 1;
}

//- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    return UITableViewAutomaticDimension;
//}

- (void)configureCell:(OCBoardTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView
{
    OCArticle *article = [[self activeModel] objectAtIndex:indexPath.row];
    cell.titleLabel.text = article.title;
    cell.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    if (article.URL) {
        cell.commentCountLabel.text = [NSString stringWithFormat:@"%d", article.numberOfComments];
        cell.commentCountLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else {
        cell.commentCountLabel.text = nil;
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    if (article.name) {
        cell.imageNameView.image = nil;
        cell.nameLabel.text = [article.name stringByAppendingString:@"님"];
    } else {
        [cell.imageNameView sd_setImageWithURL:article.imageNameURL completed:NULL];
        cell.nameLabel.text = @"님";
    }
    cell.nameLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    
    // fixme
    if (article.isNotice) {
        cell.nameLabel.text = [cell.nameLabel.text stringByAppendingString:@" [공지]"];
    }
    if (article.category) {
        cell.nameLabel.text = [cell.nameLabel.text stringByAppendingFormat:@" - %@", article.category];
    }
    
    if (_board.isImage) {
        [cell.imageView sd_setImageWithURL:article.images[0]];
        cell.detailTextLabel.text = article.content;
        cell.commentCountLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)[article.comments count]];
    }
}

- (OCBoardTableViewCell *)prototypeCell
{
    if (!_prototypeCell) {
        _prototypeCell = [self.tableView dequeueReusableCellWithIdentifier:REUSE_IDENTIFIER];
    }
    return _prototypeCell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Navigation

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    if ([identifier isEqualToString:@"article"]) {
        NSArray *articles = [self activeModel];
        NSIndexPath *indexPath = [[self activeTableView] indexPathForSelectedRow];
        return [articles[indexPath.row] URL] != nil;
    } else if ([identifier isEqualToString:@"write"]) {
        if (_parser.writeURL) {
            return YES;
        }
        // fixme
        OCAlert(@"글 쓰기 권한이 없습니다. 로그인 해보세요.");
        return NO;
    }
    return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"article"]) {
        OCArticleTableViewController *vc = segue.destinationViewController;
        vc.article = [[self activeModel] objectAtIndex:[[self activeTableView] indexPathForSelectedRow].row];
    } else if ([segue.identifier isEqualToString:@"web"]) {
        OCWebViewController *vc = segue.destinationViewController;
        vc.URL = _board.URL;
    } else if ([segue.identifier isEqualToString:@"write"]) {
        UINavigationController *nc = segue.destinationViewController;
        OCComposeViewController *vc = (OCComposeViewController *) nc.topViewController;
        vc.URL = _parser.writeURL;
    }
}

- (void)setBoard:(OCBoard *)board
{
    _board = board;
    _parser = [[OCBoardParser alloc] initWithBoard:_board];
    self.title = _board.title;
    [self reload];
}

- (void)reload
{
    if (_searchController.searchResultsController == self) {
        [self searchBarSearchButtonClicked:_searchController.searchBar];
        return;
    }
    if ([_categories count]) {
        [self loadCategory];
    } else {
        [self.refreshControl beginRefreshing];
        self.tableView.contentOffset = CGPointMake(0, -CGRectGetHeight(self.refreshControl.frame));
        
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:_board.URL];
        [request addValue:_board.URL.baseURL.absoluteString forHTTPHeaderField:@"Referer"];
        
        NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            NSLog(@"글 목록");
            if (!data) {
                // fixme
                OCAlert(@"통신 오류");
                return;
            }

            _articles = [_parser parse:data];
            _categories = [_parser categories];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
                [self.refreshControl endRefreshing];
                if ([_categories count]) {
                    _categoryItem.title = _categories[0];
                    _categoryItem.enabled = YES;
                }
            });
        }];
        [task resume];
        NSLog(@"글 목록 요청");
    }
}

- (void)loadMoreForce:(BOOL)force
{
    NSURLRequest *request = force ? [[self activeParser] requestForNextSearch] : [[self activeParser] requestForNextPage];
    if (!request) {
        if (!force && [[self activeParser] requestForNextSearch]) {
            UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
            [button setTitle:@"*다음검색*" forState:UIControlStateNormal];
            [button addTarget:self action:@selector(nextSearch) forControlEvents:UIControlEventTouchUpInside];
            [button sizeToFit];
            [self activeTableView].tableFooterView = button;
            _moreIndicator = nil; // fixme
        } else {
            // fixme
        }
        return;
    }
    
    [self sendRequest:request more:YES];
}

- (void)nextSearch {
    [self loadMoreForce:YES];
}

- (UIActivityIndicatorView *)moreIndicator {
    if (!_moreIndicator) {
        _moreIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [_moreIndicator sizeToFit];
        [self activeTableView].tableFooterView = _moreIndicator;
    }
    return _moreIndicator;
}

- (UITableView *)activeTableView {
    return _searchController.active ? ((UITableViewController *) _searchController.searchResultsController).tableView : self.tableView;
}

- (BOOL)shouldAutorotate
{
    return NO;
}

#pragma mark - Search bar delegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    if (!_searchParser) {
        _searchParser = [[OCBoardParser alloc] initWithBoard:_board];
    }
    
    NSURLRequest *request = [_searchParser requestForSearchString:searchBar.text field:_searchField];
    [self sendRequest:request more:NO];
}

- (void)sendRequest:(NSURLRequest *)request completion:(void (^)(NSData *data, NSURLResponse *response, NSError *error))block {
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:block];
    [task resume];
}

- (IBAction)showCategoryView:(id)sender {
    UIActionSheet *sheet = [[UIActionSheet alloc] init];
    sheet.tag = kCategoryActionSheetTag;
    for (NSString *category in _categories) {
        [sheet addButtonWithTitle:category];
    }
    sheet.cancelButtonIndex = [sheet addButtonWithTitle:@"취소"];
    sheet.delegate = self;
    [sheet showFromBarButtonItem:sender animated:YES];
}

#pragma mark - Action sheet delegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex != actionSheet.cancelButtonIndex) {
        if (actionSheet.tag == kCategoryActionSheetTag) {
            NSString *category = _categories[buttonIndex];
            _categoryItem.title = category;
            [self loadCategory];
        } else {
            NSLog(@"unknown action sheet!");
        }
    }
}

- (void)setSearchField:(NSInteger)field title:(NSString *)title {
    _searchField = field;
    _searchFieldItem.title = title;
}

- (void)loadCategory {
    [self.refreshControl beginRefreshing];
//    self.tableView.contentOffset = CGPointMake(0, -CGRectGetHeight(self.refreshControl.frame));

    NSURLRequest *request = [_parser requestForCategory:_categoryItem.title];
    [self sendRequest:request more:NO];
}

- (void)sendRequest:(NSURLRequest *)request more:(BOOL)more {
    if (more) {
        [[self moreIndicator] startAnimating];
    } else if (_searchController.active) {
        [((UITableViewController *) _searchController.searchResultsController).refreshControl beginRefreshing];
    }
    
    [self sendRequest:request completion:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (data) {
            NSArray *array;
            if (more) {
                array = [self activeModel];
            } else {
                array = [NSArray array];
            }
            array = [array arrayByAddingObjectsFromArray:[[self activeParser] parse:data]];
            if (_searchController.active) {
                _searchResult = array;
            } else {
                _articles = array;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [[self activeTableView] reloadData];
                if (more) {
                    [[self moreIndicator] stopAnimating];
                } else {
                    UIRefreshControl *refreshControl = _searchController.active ? ((UITableViewController *) _searchController.searchResultsController).refreshControl : self.refreshControl;
                    [refreshControl endRefreshing];
                }
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (more) {
                    [[self moreIndicator] stopAnimating];
                }
                OCAlert(error.localizedDescription);
            });
        }
    }];    
}

- (OCBoardParser *)activeParser {
    return _searchController.active ? _searchParser : _parser;
}

- (NSArray *)activeModel {
    return _searchController.active ? _searchResult : _articles;
}

@end
