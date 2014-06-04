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

static NSString* REUSE_IDENTIFIER = @"board cell";

@interface OCBoardTableViewController ()

@end

@implementation OCBoardTableViewController
{
    OCBoardParser *_parser;
    NSArray *_articles;
    OCBoardTableViewCell *_prototypeCell;
    UIActivityIndicatorView *_moreIndicator;
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
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(reload) forControlEvents:UIControlEventValueChanged];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_articles count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OCBoardTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:REUSE_IDENTIFIER];
//    if (!cell) {
//        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:REUSE_IDENTIFIER];
//    }

    [self configureCell:cell forRowAtIndexPath:indexPath];
    
    if (indexPath.row == [_articles count] - 1) {
        [self loadMore];
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self configureCell:[self prototypeCell] forRowAtIndexPath:indexPath];
    [[self prototypeCell] layoutIfNeeded];
    return [[self prototypeCell].contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height + 1;
}

//- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    return UITableViewAutomaticDimension;
//}

- (void)configureCell:(OCBoardTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    OCArticle *article = _articles[indexPath.row];
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
    return [_articles[[self.tableView indexPathForSelectedRow].row] URL] != nil;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"article"]) {
        OCArticleTableViewController *vc = segue.destinationViewController;
        vc.article = _articles[[self.tableView indexPathForSelectedRow].row];
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

- (void)reload
{
    [self.refreshControl beginRefreshing];
    self.tableView.contentOffset = CGPointMake(0, -CGRectGetHeight(self.refreshControl.frame));
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData* data = [NSData dataWithContentsOfURL:_board.URL];
        _articles = [_parser parse:data];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
            [self.refreshControl endRefreshing];
        });
    });
}

- (void)loadMore
{
    if (!_moreIndicator) {
        _moreIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [_moreIndicator sizeToFit];
        self.tableView.tableFooterView = _moreIndicator;
    }
    [_moreIndicator startAnimating];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData *data = [NSData dataWithContentsOfURL:[_parser URLForNextPage]];
        _articles = [_articles arrayByAddingObjectsFromArray:[_parser parse:data]];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
            [_moreIndicator stopAnimating];
        });
    });
}

- (BOOL)shouldAutorotate
{
    return NO;
}

@end
