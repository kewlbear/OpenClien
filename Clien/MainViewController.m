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

@interface MainViewController ()

@end

@implementation MainViewController
@synthesize logView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Clien.net";
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    logView.text = @"ready.";
    [self reload];
}

- (void)reload {
    NSURL* URL = [NSURL URLWithString:@"http://clien.career.co.kr"];
    NSURLRequest* request = [NSURLRequest requestWithURL:URL];
    NSURLConnection* connection = [NSURLConnection connectionWithRequest:request delegate:self];
    if (connection) {
        receivedData = [NSMutableData data];
        UIActivityIndicatorView* indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        [indicator startAnimating];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:indicator];
    } else {
        logView.text = [logView.text stringByAppendingString:@"\nconnection failed."];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*) response;
    logView.text = [logView.text stringByAppendingFormat:@"\nresponse=%d", httpResponse.statusCode];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [receivedData appendData:data];
    logView.text = [logView.text stringByAppendingFormat:@"\nlength=%u", data.length];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    logView.text = [logView.text stringByAppendingFormat:@"\n%@", error];
    [self setRefreshButton];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    NSString* response = [[NSString alloc] initWithData:receivedData encoding:NSUTF8StringEncoding];
    NSScanner* scanner = [NSScanner scannerWithString:[response substringFrom:@"<div id=\"snb_navi1\">" to:@"</div>"]];
    NSMutableArray* array = [NSMutableArray array];
    while (!scanner.isAtEnd) {
        Board* board = [[Board alloc] init];
        [scanner skip:@"href=\""];
        NSString* href;
        if (![scanner scanUpToString:@"\"" intoString:&href]) {
            break;
        }
        board.href = href;
        [scanner skip:@"src=\""];
        NSString* src;
        [scanner scanUpToString:@"\"" intoString:&src];
        board.src = src;
        [scanner skip:@">"];
        NSString* title;
        [scanner scanUpToString:@"<" intoString:&title];
        board.title = title;
        [array addObject:board];
        logView.text = [logView.text stringByAppendingFormat:@"\nhref=%@ src=%@ title=%@", href, src, title];
    }
    boards = array;
    [self.tableView reloadData];
    [self setRefreshButton];
}

- (void)setRefreshButton {
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(reload)];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [boards count];
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString* CellIdentifier = @"cell";
    UITableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    Board* board = [boards objectAtIndex:indexPath.row];
    cell.textLabel.text = board.title;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Board* board = [boards objectAtIndex:indexPath.row];
    BoardViewController* controller = [[BoardViewController alloc] initWithStyle:UITableViewStylePlain];
    controller.href = board.href;
    [self.navigationController pushViewController:controller animated:YES];
    NSLog(@"%@", board.href);
}

- (void)viewDidUnload
{
    [self setLogView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
