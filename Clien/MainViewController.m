//
//  MainViewController.m
//  Clien
//
//  Created by 안창범 on 12. 8. 21..
//  Copyright (c) 2012년 안창범. All rights reserved.
//

#import "MainViewController.h"
#import "Board.h"
#import "BoardViewController.h"
#import "NSString+SubstringFromTo.h"
#import "NSScanner+Skip.h"
#import "UIImageView+AFNetworking.h"
#import "MainCell.h"
#import "UIViewController+Stack.h"
#import "AFHTTPClient.h"
#import "AppDelegate.h"
#import "SettingsViewController.h"
#import "UIViewController+URL.h"

@interface MainViewController () {
    NSURL* URL;
    UIActivityIndicatorView* indicator;
}

@end

@implementation MainViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self sharedInit];

        UIButton* infoButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
        [infoButton addTarget:self action:@selector(openSettings:) forControlEvents:UIControlEventTouchUpInside];
        infoButton.frame = UIEdgeInsetsInsetRect(infoButton.frame, UIEdgeInsetsMake(0, -10, 0, -10));
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:infoButton];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self sharedInit];
    }
    return self;
}

- (void)sharedInit {
    self.title = @"Clien.net";
    URL = [NSURL URLWithString:@"http://www.clien.net"];
    
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
}

- (IBAction)openSettings:(id)sender {
    SettingsViewController* vc = [[SettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
    UINavigationController* nc = [[UINavigationController alloc] initWithRootViewController:vc];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        nc.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
        [self presentViewController:nc animated:YES completion:NULL];
    } else {
        UIPopoverController* popover = [[UIPopoverController alloc] initWithContentViewController:nc];
        [popover presentPopoverFromBarButtonItem:self.navigationItem.rightBarButtonItem permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
}

//- (void)awakeFromNib {
//    self.title = @"Clien.net";
//    URL = [NSURL URLWithString:@"http://clien.career.co.kr"];
////    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(reload)];
//    
//    self.navigationItem.leftBarButtonItem = self.editButtonItem;
//    
////    AppDelegate* appDelegate = (AppDelegate*) [UIApplication sharedApplication].delegate;
////    _managedObjectContext = appDelegate.managedObjectContext;
//}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(reload) forControlEvents:UIControlEventValueChanged];

    indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    indicator.frame = CGRectMake(0, 0, self.tableView.rowHeight, self.tableView.rowHeight);
    self.tableView.tableFooterView = indicator;

//    [self setGestureRecognizer];
    
    if (![self loadFromCoreDataIncludingHidden:NO]) {
        [self reload];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self openFirstBoardIfPad];
}

- (void)openFirstBoardIfPad {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        UINavigationController* nc = self.splitViewController.viewControllers[1];
        if (![nc.viewControllers[0] isKindOfClass:[BoardViewController class]]) {
            int section;
            if ([self.tableView numberOfRowsInSection:0]) {
                section = 0;
            } else {
                section = 1;
            }
            NSIndexPath* indexPath = [NSIndexPath indexPathForRow:0 inSection:section];
            [self tableView:self.tableView didSelectRowAtIndexPath:indexPath];
//            [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
        }
    }
}

- (BOOL)loadFromCoreDataIncludingHidden:(BOOL)hidden {
    NSFetchRequest* request = [[NSFetchRequest alloc] init];
    NSEntityDescription* entity = [NSEntityDescription entityForName:@"Board" inManagedObjectContext:_managedObjectContext];
    request.entity = entity;
    
    NSSortDescriptor* sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"row" ascending:YES];
    NSArray* sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    request.sortDescriptors = sortDescriptors;
    
    NSMutableArray* array = [NSMutableArray array];
    for (int section = 0; section < 3; ++section) {
        NSString* format;
        if (hidden || section == 0) {
            format = @"section = %d";
        } else {
            format = @"(section = %d) AND (hidden = NIL OR hidden = NO)";
        }
        request.predicate = [NSPredicate predicateWithFormat:format, section];
        
        NSError* error;
        NSMutableArray* boards = [[_managedObjectContext executeFetchRequest:request error:&error] mutableCopy];
        if (!boards) {
            NSLog(@"%s: boards is nil", __func__);
            // TODO
            break;
        }
        NSLog(@"%s: section=%d count=%u", __func__, section, boards.count);
        [array addObject:boards];
    }
    if ([[array objectAtIndex:1] count] > 0) {
        sections = array;
        [self.tableView reloadData];
        return YES;
    }
    return NO;
}

- (void)reload {
    [indicator startAnimating];

    NSURLRequest* request = [NSURLRequest requestWithURL:URL];
    [[[AFHTTPClient clientWithBaseURL:URL] HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString* response = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        NSLog(@"%s: %@", __func__, response);
        NSMutableArray* array = [NSMutableArray array];
        if (sections) {
            [array addObject:[sections objectAtIndex:0]];
        } else {
            [array addObject:[NSMutableArray array]];
        }
        [self deleteNonFavorites];
        [array addObject:[self parseSection:[response substringFrom:@"<div id=\"snb_navi1\">" to:@"</div>"] index:1]];
        [array addObject:[self parseSection:[response substringFrom:@"<div id=\"snb_navi2\">" to:@"</div>"] index:2]];
        [self save];
        sections = array;
        [self.tableView reloadData];
        [self setRefreshButton];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%s: %@", __func__, error);
        // TODO:
        [self setRefreshButton];
    }] start];
}

- (void)deleteNonFavorites {
    NSFetchRequest* request = [[NSFetchRequest alloc] init];
    NSEntityDescription* entity = [NSEntityDescription entityForName:@"Board" inManagedObjectContext:_managedObjectContext];
    request.entity = entity;
    
    request.predicate = [NSPredicate predicateWithFormat:@"section > 0"];
    
    NSError* error;
    NSArray* boards = [_managedObjectContext executeFetchRequest:request error:&error];
    if (boards) {
        for (Board* board in boards) {
            [_managedObjectContext deleteObject:board];
        }
    } else {
        NSLog(@"%s: boards is nil: %@", __func__, error);
        // TODO
    }
}

- (void)save {
    NSError* error;
    if (![_managedObjectContext save:&error]) {
        NSLog(@"%s: %@", __func__, error);
        // TODO:
    }
}

- (NSArray*)parseSection:(NSString*)string index:(int)section {
    NSMutableArray* boards = [NSMutableArray array];
    NSScanner* scanner = [NSScanner scannerWithString:[string stringByRemovingHTMLComments]];
    int row = 0;
    while (!scanner.isAtEnd) {
        [scanner skip:@"href=\""];
        NSString* href;
        if (![scanner scanUpToString:@"\"" intoString:&href]) {
            break;
        }
        [scanner skip:@">"];
        if ([scanner scanString:@"<img" intoString:NULL]) {
            [scanner skip:@">"];
        }
        if ([scanner scanString:@"<font" intoString:NULL]) {
            [scanner skip:@">"];
        }
        NSString* title;
        [scanner scanUpToString:@"<" intoString:&title];
        NSLog(@"%s: %@ %@", __func__, title, href);
        if ([href rangeOfString:@"board.php"].location != NSNotFound) {
            Board* board = (Board*) [NSEntityDescription insertNewObjectForEntityForName:@"Board" inManagedObjectContext:_managedObjectContext];
            board.url = [[NSURL URLWithString:href relativeToURL:URL] absoluteString];
            board.title = title;
            board.section = [NSNumber numberWithInt:section];
            board.row = [NSNumber numberWithInt:row];
            [boards addObject:board];
            ++row;
        } else {
            NSLog(@"%s: bad href=%@", __func__, href);
        }
    }
    return boards;
}

- (void)setRefreshButton {
    [indicator stopAnimating];
    [self.refreshControl endRefreshing];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [sections count];
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    static NSString* titles[] = {@"즐겨찾기", @"게시판", @"소모임"};
    return titles[section];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[sections objectAtIndex:section] count];
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString* CellIdentifier = @"main cell";
    UITableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    Board* board = [[sections objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    if (indexPath.section == 0) {
        cell.editingAccessoryView = nil;
    } else {
        if (!cell.editingAccessoryView) {
            UISwitch* toggle = [[UISwitch alloc] initWithFrame:CGRectZero];
            [toggle addTarget:self action:@selector(toggle:) forControlEvents:UIControlEventValueChanged];
            cell.editingAccessoryView = toggle;
        }
        cell.editingAccessoryView.tag = indexPath.section * 100 + indexPath.row;
        [(UISwitch*) cell.editingAccessoryView setOn:!board.hidden.boolValue];
    }
    cell.textLabel.text = board.title;
//    cell.imageView.image = [UIImage imageNamed:@"glyphicons_114_list"];
    return cell;
}

- (void)toggle:(id)sender {
    int tag = [sender tag];
    NSLog(@"%s: %d", __func__, tag);
    Board* board = [[sections objectAtIndex:tag / 100] objectAtIndex:tag % 100];
    board.hidden = [NSNumber numberWithBool:!board.hidden.boolValue];
    [self save];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView.editing) {
        return;
    }
    
    Board* board = [[sections objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    NSLog(@"%s: URL=%@", __func__, board.url);
    BoardViewController* controller = [[BoardViewController alloc] initWithStyle:UITableViewStylePlain];
    controller.URL = [NSURL URLWithString:board.url];
    controller.title = board.title;
//    [self.navigationController pushViewController:controller animated:YES];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [self push:controller];
    } else {
        UINavigationController* nc = (UINavigationController*) self.splitViewController.viewControllers[1];
        controller.navigationItem.leftBarButtonItem = nc.navigationBar.topItem.leftBarButtonItem;
        nc.viewControllers = @[controller];
    }
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

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    Board* board = [[sections objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    if (editingStyle == UITableViewCellEditingStyleInsert) {
        Board* copy = (Board*) [NSEntityDescription insertNewObjectForEntityForName:@"Board" inManagedObjectContext:_managedObjectContext];
        copy.title = board.title;
        copy.url = board.url;
        copy.section = [NSNumber numberWithInt:0];
        copy.row = [NSNumber numberWithInt:[[sections objectAtIndex:0] count]];
        [self save];
        [[sections objectAtIndex:0] addObject:copy];
        [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:copy.row.intValue inSection:copy.section.intValue]] withRowAnimation:UITableViewRowAnimationAutomatic];
    } else {
        [_managedObjectContext deleteObject:board];
        [self save];
        [[sections objectAtIndex:0] removeObjectAtIndex:indexPath.row];
        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.section == 0;
}

- (NSIndexPath*)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath {
    if (proposedDestinationIndexPath.section == 0) {
        return proposedDestinationIndexPath;
    } else {
        return sourceIndexPath;
    }
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    if (destinationIndexPath.row > sourceIndexPath.row) {
        for (int row = sourceIndexPath.row + 1; row <= destinationIndexPath.row; ++row) {
            Board* board = [[sections objectAtIndex:0] objectAtIndex:row];
            board.row = [NSNumber numberWithInt:board.row.intValue - 1];
        }
    } else if (destinationIndexPath.row < sourceIndexPath.row) {
        for (int row = destinationIndexPath.row; row < sourceIndexPath.row; ++row) {
            Board* board = [[sections objectAtIndex:0] objectAtIndex:row];
            board.row = [NSNumber numberWithInt:board.row.intValue + 1];
        }
    }
    Board* board = [[sections objectAtIndex:0] objectAtIndex:sourceIndexPath.row];
    board.row = [NSNumber numberWithInt:destinationIndexPath.row];
    [[sections objectAtIndex:0] removeObjectAtIndex:sourceIndexPath.row];
    [[sections objectAtIndex:0] insertObject:board atIndex:destinationIndexPath.row];
    [self save];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        return UITableViewCellEditingStyleDelete;
    } else {
        return UITableViewCellEditingStyleInsert;
    }
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    self.navigationItem.rightBarButtonItem.enabled = !editing;
    [self loadFromCoreDataIncludingHidden:editing];
    
    [super setEditing:editing animated:animated];
}

- (void)tableView:(UITableView *)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    self.editButtonItem.enabled = NO;
}

- (void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    self.editButtonItem.enabled = YES;
}

@end
