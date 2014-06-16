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

enum {
    kCategoryActionSheetTag,
    kSearchFieldActionSheetTag
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
    UISearchDisplayController *_searchController;
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
    
    UISearchBar *searchBar = [[UISearchBar alloc] init];
    searchBar.delegate = self;
    UIToolbar *toolbar = [[UIToolbar alloc] init];
    _searchFieldItem = [[UIBarButtonItem alloc] initWithTitle:@"제목" style:UIBarButtonItemStyleBordered target:self action:@selector(showSearchFieldView:)];
    toolbar.items = @[_searchFieldItem];
    [toolbar sizeToFit];
    searchBar.inputAccessoryView = toolbar;
    [searchBar sizeToFit];
    self.tableView.tableHeaderView = searchBar;
    _searchController = [[UISearchDisplayController alloc] initWithSearchBar:searchBar contentsController:self];
    _searchController.delegate = self;
    _searchController.searchResultsDataSource = self;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (_comment) {
        self.searchDisplayController.active = YES;
        [self.searchDisplayController.searchBar becomeFirstResponder];
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
    return tableView == self.tableView ? [_articles count] : [_searchResult count];
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
    OCArticle *article = [(tableView == self.tableView ? _articles : _searchResult) objectAtIndex:indexPath.row];
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
        [cell.imageNameView setImageWithURL:article.imageNameURL];
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
        [cell.imageView setImageWithURL:article.images[0]];
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
    NSArray *articles = [self activeModel];
    NSIndexPath *indexPath = [[self activeTableView] indexPathForSelectedRow];
    return [articles[indexPath.row] URL] != nil;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"article"]) {
        OCArticleTableViewController *vc = segue.destinationViewController;
        vc.article = [[self activeModel] objectAtIndex:[[self activeTableView] indexPathForSelectedRow].row];
    } else {
        OCWebViewController *vc = segue.destinationViewController;
        vc.URL = _board.URL;
    }
}

//- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    OCArticleTableViewController *vc = [[OCArticleTableViewController alloc] initWithStyle:UITableViewStylePlain];
//    vc.article = _articles[indexPath.row];
//    [self.navigationController pushViewController:vc animated:YES];
//}

- (void)setBoard:(OCBoard *)board
{
    _board = board;
    _parser = [[OCBoardParser alloc] initWithBoard:_board];
    self.title = _board.title;
    [self reload];
}

- (void)setComment:(OCComment *)comment {
    _comment = comment;
    _board = [comment.article.URL board];
}

- (void)reload
{
    if ([_categories count]) {
        [self loadCategory];
    } else {
        [self.refreshControl beginRefreshing];
        self.tableView.contentOffset = CGPointMake(0, -CGRectGetHeight(self.refreshControl.frame));
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSData* data = [NSData dataWithContentsOfURL:_board.URL];
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
        });
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
    return self.searchDisplayController.active ? self.searchDisplayController.searchResultsTableView : self.tableView;
}

- (BOOL)shouldAutorotate
{
    return NO;
}

- (IBAction)activateSearch:(id)sender {
    // fixme 검색 막대의 취소 버튼을 터치할 수 없는 문제 회피
    [self.tableView scrollRectToVisible:self.tableView.tableHeaderView.frame animated:NO];
    
//    [self.searchDisplayController setActive:YES animated:YES];
    [self.searchDisplayController.searchBar becomeFirstResponder];
}

- (void)searchDisplayController:(UISearchDisplayController *)controller didLoadSearchResultsTableView:(UITableView *)tableView {
    tableView.delegate = self;
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
//    if (_comment) {
//        _comment = nil;
//        [self searchBarSearchButtonClicked:controller.searchBar];
//    }
    return NO;
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    if (_comment) {
        searchBar.text = _comment.memberId;
        _comment = nil;
        _searchField = OCSearchFieldMemberId;
        _searchFieldItem.title = @"회원아이디"; // fixme
        [self searchBarSearchButtonClicked:searchBar];
    }
}

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

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex != actionSheet.cancelButtonIndex) {
        if (actionSheet.tag == kCategoryActionSheetTag) {
            NSString *category = _categories[buttonIndex];
            _categoryItem.title = category;
            [self loadCategory];
        } else if (actionSheet.tag == kSearchFieldActionSheetTag) {
            _searchField = (int) buttonIndex;
            _searchFieldItem.title = [actionSheet buttonTitleAtIndex:buttonIndex];
        } else {
            NSLog(@"unknown action sheet!");
        }
    }
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
            if (self.searchDisplayController.active) {
                _searchResult = array;
            } else {
                _articles = array;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [[self activeTableView] reloadData];
                if (more) {
                    [[self moreIndicator] stopAnimating];
                } else {
                    [self.refreshControl endRefreshing];
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
    return self.searchDisplayController.active ? _searchParser : _parser;
}

- (NSArray *)activeModel {
    return self.searchDisplayController.active ? _searchResult : _articles;
}

- (void)showSearchFieldView:(id)sender {
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"취소" destructiveButtonTitle:nil otherButtonTitles:@"제목", @"내용", @"제목+내용", @"회원아이디", @"회원아이디(코)", @"이름", @"이름(코)", nil];
    sheet.tag = kSearchFieldActionSheetTag;
//    [sheet showFromBarButtonItem:sender animated:YES];
    [sheet showFromToolbar:self.navigationController.toolbar];
}

@end
