//
//  OCMainTableViewController.m
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

#import "OCMainTableViewController.h"
#import <OpenClien/OpenClien.h>
#import "OCBoardTableViewController.h"
#import "OCMainTableViewCell.h"
#import "OCWebViewController.h"
#import "OCSession.h"
#import "Board.h"
#import "OCImageBoardViewController.h"

static NSString *kBoard = @"board";

@interface OCMainTableViewController ()

@end

@implementation OCMainTableViewController
{
    OCMainParser *_parser;
    NSArray *_boards;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        self.title = @"Open Clien";
        _parser = [[OCMainParser alloc] init];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        _parser = [[OCMainParser alloc] init];
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

    [self load];
    
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [_boards count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_boards[section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *ReuseIdentifier = @"main cell";
    OCMainTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ReuseIdentifier];
//    if (!cell) {
//        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ReuseIdentifier];
//    }
    
    [self configureCell:cell forIndexPath:indexPath];
    
    return cell;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    static NSString *titles[] = {@"즐겨찾기", @"게시판", @"소모임"};
    return titles[section];
}

- (void)configureCell:(OCMainTableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
    OCBoard *board = _boards[indexPath.section][indexPath.row];
    cell.nameLabel.text = board.title;
    cell.nameLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [_context deleteObject:_boards[0][indexPath.row]];
        
        [_boards[0] removeObjectAtIndex:indexPath.row];
        
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        Board *board = _boards[indexPath.section][indexPath.row];
        Board *b = [NSEntityDescription insertNewObjectForEntityForName:@"Board" inManagedObjectContext:_context];
        b.title = board.title;
        b.data = board.data;
        b.section = 0;
        NSUInteger row = [_boards[0] count];
        b.row = @(row);
        
        _boards[0][row] = b;
        
        [tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:row inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    NSError *error;
    if (![_context save:&error]) {
        NSLog(@"%s: %@", __PRETTY_FUNCTION__, error);
    }
}

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

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return indexPath.section > 0 ? UITableViewCellEditingStyleInsert : UITableViewCellEditingStyleDelete;
}

#pragma mark - Navigation

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    if ([identifier isEqualToString:@"board"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        Board *board = _boards[indexPath.section][indexPath.row];
        NSKeyedUnarchiver *decoder = [[NSKeyedUnarchiver alloc] initForReadingWithData:board.data];
        OCBoard *b = [decoder decodeObjectForKey:kBoard];
        if (b.isImage) {
            [self performSegueWithIdentifier:@"image" sender:b];
            return NO;
        }
    }
    return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"board"]) {
        OCBoardTableViewController *vc = [segue destinationViewController];
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        Board *board = _boards[indexPath.section][indexPath.row];
        NSKeyedUnarchiver *decoder = [[NSKeyedUnarchiver alloc] initForReadingWithData:board.data];
        vc.board = [decoder decodeObjectForKey:kBoard];
    } else if ([segue.identifier isEqualToString:@"web"]) {
        OCWebViewController *vc = [segue destinationViewController];
        vc.URL = [OCMainParser URL];
    } else if ([segue.identifier isEqualToString:@"scrap"]) {
        OCWebViewController *vc = [segue destinationViewController];
        vc.URL = [NSURL URLWithString:@"http://m.clien.net/cs3/scrap"];
    } else if ([segue.identifier isEqualToString:@"image"]) {
        OCImageBoardViewController *vc = segue.destinationViewController;
        vc.board = sender;
    } else {
        OCWebViewController *vc = [segue destinationViewController];
        vc.URL = [NSURL URLWithString:@"http://best.mqoo.com/?site=clien&time=3&orderby=hit"];
    }
}

- (void)reload
{
    [self.refreshControl beginRefreshing];
    self.tableView.contentOffset = CGPointMake(0, -CGRectGetHeight(self.refreshControl.frame));
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData* data = [NSData dataWithContentsOfURL:[OCMainParser URL]];
        if (!data) {
            // fixme
            OCAlert(@"통신 오류");
            return;
        }

        NSArray *sections = [_parser parse:data];
        [self deleteNonFavorites];
        [self save:sections];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self load];
            [self.refreshControl endRefreshing];
        });
    });
}

- (void)deleteNonFavorites {
    NSFetchRequest* request = [[NSFetchRequest alloc] init];
    NSEntityDescription* entity = [NSEntityDescription entityForName:@"Board" inManagedObjectContext:_context];
    request.entity = entity;
    
    request.predicate = [NSPredicate predicateWithFormat:@"section > 0"];
    
    NSError* error;
    NSArray* boards = [_context executeFetchRequest:request error:&error];
    if (boards) {
        for (Board* board in boards) {
            [_context deleteObject:board];
        }
    } else {
        NSLog(@"%s: boards is nil: %@", __func__, error);
        // TODO
    }
}

- (void)save:(NSArray *)sections
{
    for (int section = 0; section < [sections count]; ++section) {
        NSArray *rows = sections[section];
        for (int row = 0; row < [rows count]; ++row) {
            OCBoard *board = rows[row];
            Board *b = [NSEntityDescription insertNewObjectForEntityForName:@"Board" inManagedObjectContext:_context];
            b.title = board.title;
            
            NSMutableData *data = [NSMutableData data];
            NSKeyedArchiver *coder = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
            [coder encodeObject:board forKey:kBoard];
            [coder finishEncoding];
            
            b.data = data;
            
            b.section = @(section + 1);
            b.row = @(row);
        }
    }
    NSError *error;
    if (![_context save:&error]) {
        NSLog(@"%@", error);
    }
}

- (void)load
{
    NSFetchRequest* request = [[NSFetchRequest alloc] init];
    NSEntityDescription* entity = [NSEntityDescription entityForName:@"Board" inManagedObjectContext:_context];
    request.entity = entity;
    
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"section" ascending:YES],
                                [NSSortDescriptor sortDescriptorWithKey:@"row" ascending:YES]];
    
//        NSString* format;
//        if (hidden || section == 0) {
//            format = @"section = %d";
//        } else {
//            format = @"(section = %d) AND (hidden = NIL OR hidden = NO)";
//        }
//        request.predicate = [NSPredicate predicateWithFormat:format, section];
        
    NSError* error;
    NSArray* boards = [_context executeFetchRequest:request error:&error];
    if (!boards) {
        NSLog(@"%s: %@", __func__, error);
        // TODO
    }
    
    NSMutableArray *sections = [NSMutableArray arrayWithObjects:
                             [NSMutableArray array],
                             [NSMutableArray array],
                             [NSMutableArray array],
                             nil];
    for (Board *board in boards) {
        NSMutableArray *section = sections[[board.section intValue]];
        [section addObject:board];
    }
    if ([sections[1] count]) {
        _boards = sections;
        
        [self.tableView reloadData];
    } else {
        [self reload];
    }
}

- (BOOL)shouldAutorotate
{
    return NO;
}

- (IBAction)logout:(id)sender {
    [[OCSession defaultSession] logout:^(NSError *error) {
        // fixme
        NSLog(@"%@", error);
    }];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    
    // fixme
}

@end
