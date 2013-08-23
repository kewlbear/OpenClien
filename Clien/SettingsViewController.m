//
//  SettingsViewController.m
//  Clien
//
//  Created by 안창범 on 13. 8. 7..
//  Copyright (c) 2013년 안창범. All rights reserved.
//

#import "SettingsViewController.h"
#import "UIViewController+Stack.h"
#import "Settings.h"
#import "AppDelegate.h"
#import "WebViewController.h"

enum {
    SaveLogRow,
    ViewLogRow
};

@interface SettingsViewController ()

@end

@implementation SettingsViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        self.title = @"설정";
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismiss)];
    }
    return self;
}

- (void)dismiss {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    [self setGestureRecognizer];
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
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    }
    
    if (indexPath.row == SaveLogRow) {
        cell.textLabel.text = @"로그 저장";
        UISwitch* aSwitch = [[UISwitch alloc] init];
        aSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:SettingsDebugKey];
        [aSwitch addTarget:self action:@selector(debugChanged:) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = aSwitch;
    } else if (indexPath.row == ViewLogRow) {
        cell.textLabel.text = @"로그 보기";
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    return cell;
}

- (void)debugChanged:(UISwitch*)sender {
    [[NSUserDefaults standardUserDefaults] setBool:sender.on forKey:SettingsDebugKey];
    
    static int savedStderr;
    if (sender.on) {
        savedStderr = [self dup:STDERR_FILENO];
        if (savedStderr >= 0) {
            NSLog(@"%d is original stderr", savedStderr);
        }
        NSURL* url = [self logURL];
        if (freopen(url.path.UTF8String, "w", stderr)) {
            NSLog(@"redirected stderr to %@", url.path);
        } else {
            NSLog(@"%s", strerror(errno));
        }
    } else {
        [self close:STDERR_FILENO];
        int restoredStderr = [self dup:savedStderr];
        assert(restoredStderr == STDERR_FILENO);
        NSLog(@"restored stderr");
        [self close:savedStderr];
    }
}

- (NSURL*)logURL {
    AppDelegate* appDelegate = (AppDelegate*) [UIApplication sharedApplication].delegate;
    return [[appDelegate applicationDocumentsDirectory] URLByAppendingPathComponent:@"log"];
}

- (int)dup:(int)fd {
    int newFd = dup(fd);
    if (newFd < 0) {
        NSLog(@"dup: %s", strerror(errno));
    }
    return newFd;
}

- (void)close:(int)fd {
    if (close(fd) < 0) {
        NSLog(@"close: %s", strerror(errno));
    }
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
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
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

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == ViewLogRow) {
        // fixme provide proper viewer
        WebViewController* vc = [[WebViewController alloc] init];
        vc.URL = [self logURL];
        [self.navigationController pushViewController:vc animated:YES];
    }
}

@end
