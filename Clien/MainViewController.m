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

@interface MainViewController () {
    NSURL* URL;
}

@end

@implementation MainViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Clien.net";
        URL = [NSURL URLWithString:@"http://clien.career.co.kr"];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self reload];
}

- (void)reload {
    NSURLRequest* request = [NSURLRequest requestWithURL:URL];
    NSURLConnection* connection = [NSURLConnection connectionWithRequest:request delegate:self];
    if (connection) {
        receivedData = [NSMutableData data];
        UIActivityIndicatorView* indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        [indicator startAnimating];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:indicator];
    } else {
        // TODO:
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response {
    // TODO:
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [receivedData appendData:data];
    // TODO:
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    // TODO:
    [self setRefreshButton];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    NSString* response = [[NSString alloc] initWithData:receivedData encoding:NSUTF8StringEncoding];
    NSLog(@"%s: %@", __func__, response);
    NSMutableArray* array = [NSMutableArray array];
    [array addObject:[self parseSection:[response substringFrom:@"<div id=\"snb_navi1\">" to:@"</div>"]]];
    [array addObject:[self parseSection:[response substringFrom:@"<div id=\"snb_navi2\">" to:@"</div>"]]];
    sections = array;
    [self.tableView reloadData];
    [self setRefreshButton];
}

- (NSArray*)parseSection:(NSString*)string {
    NSMutableArray* boards = [NSMutableArray array];
    NSScanner* scanner = [NSScanner scannerWithString:[string stringByRemovingHTMLComments]];
    while (!scanner.isAtEnd) {
        Board* board = [[Board alloc] init];
        [scanner skip:@"href=\""];
        NSString* href;
        if (![scanner scanUpToString:@"\"" intoString:&href]) {
            break;
        }
        board.URL = [NSURL URLWithString:href relativeToURL:URL];
        [scanner skip:@">"];
        if ([scanner scanString:@"<img" intoString:NULL]) {
            [scanner skip:@">"];
        }
        if ([scanner scanString:@"<font" intoString:NULL]) {
            [scanner skip:@">"];
        }
        NSString* title;
        [scanner scanUpToString:@"<" intoString:&title];
        board.title = title;
        NSLog(@"%s: %@ %@ %@", __func__, title, href, board.URL);
        if (board.URL.path && [board.URL.path rangeOfString:@"board.php"].location != NSNotFound) {
            [boards addObject:board];
        } else {
            NSLog(@"%s: bad href=%@", __func__, href);
        }
    }
    return boards;
}

- (void)setRefreshButton {
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(reload)];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [sections count];
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    static NSString* titles[] = {nil, @"소모임"};
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
    cell.textLabel.text = board.title;
//    [cell.imageView setImageWithURL:[NSURL URLWithString:board.src]
//                   placeholderImage:[[UIImage alloc] init]];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Board* board = [[sections objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    NSLog(@"%s: URL=%@", __func__, board.URL);
    BoardViewController* controller = [[BoardViewController alloc] initWithStyle:UITableViewStylePlain];
    controller.URL = board.URL;
    controller.title = board.title;
//    [self.navigationController pushViewController:controller animated:YES];
    [self push:controller];
    NSLog(@"%@", board.URL);
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
