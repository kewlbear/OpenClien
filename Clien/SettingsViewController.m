//
//  SettingsViewController.m
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

#import "SettingsViewController.h"
#import "UIViewController+Stack.h"
#import "Settings.h"
#import "AppDelegate.h"
#import "WebViewController.h"
#import "AFHTTPClient.h"
#import "UIViewController+URL.h"
#import "UIViewController+GAI.h"

typedef enum {
    SwitchRow,
    URLRow,
    SimpleRow
} RowType;

typedef struct {
    char* title;
    RowType type;
    char* url;
} Row;

static Row loginRows[] = {
    {NULL, SimpleRow, "login"},
    {"자동 로그인", SwitchRow, "autoLogin"}
};

static Row myRows[] = {
    {"내 글", URLRow, "http://m.clien.net/cs3/mycontents"},
    {"스크랩", URLRow, "http://m.clien.net/cs3/scrap"},
    {"쪽지", URLRow, "http://m.clien.net/cs3/memo"},
    {"내 정보", URLRow, "http://www.clien.net/cs2/bbs/profile.php?mb_id="}
};

static Row debugRows[] = {
    {"로그 저장", SwitchRow, "saveLogs"},
    {"로그 보기", URLRow}
};

typedef struct {
    Row* rows;
    int rowCount;
} Section;

static Section sections[] = {
    {loginRows, sizeof(loginRows) / sizeof(*loginRows)},
    {myRows, sizeof(myRows) / sizeof(*myRows)},
    {debugRows, sizeof(debugRows) / sizeof(*debugRows)}
};

@interface SettingsViewController () {
    BOOL _loggedIn;
}

@end

@implementation SettingsViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        self.title = @"설정";
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismiss)];
        self.contentSizeForViewInPopover = CGSizeMake(320, 400);
        [self sendHitWithScreenName:@"Settings"];
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
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    
    [self.refreshControl beginRefreshing];
    [self refresh:self.refreshControl];
}

- (void)refresh:(id)sender {
    AFHTTPClient* client = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:@"http://m.clien.net"]];
    [client getPath:@"/cs3/main/config" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString* response = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
//        NSLog(@"%@", response);
        if ([response rangeOfString:@"<title>"].length) {
            _loggedIn = YES;
            [self.tableView reloadData];
        }
        [sender endRefreshing];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@", error);
        [sender endRefreshing];
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return sizeof(sections) / sizeof(*sections);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return sections[section].rowCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    }
    
    Row* row = sections[indexPath.section].rows + indexPath.row;
    if (row->title) {
        cell.textLabel.text = [NSString stringWithUTF8String:row->title];
    } else {
        cell.textLabel.text = [self performSelector:NSSelectorFromString([NSString stringWithFormat:@"%sTitle", row->url])];
    }
    if (row->type == SwitchRow) {
        UISwitch* aSwitch = [[UISwitch alloc] init];
        aSwitch.on = [self performSelector:sel_registerName(row->url)];
        [aSwitch addTarget:self action:NSSelectorFromString([NSString stringWithFormat:@"%sChanged:", row->url]) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = aSwitch;
    } else if (row->type == URLRow) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    return cell;
}

- (NSString*)loginTitle {
    return _loggedIn ? @"로그아웃" : @"로그인";
}

- (void)loginSelected:(NSIndexPath*)indexPath {
    if (_loggedIn) {
        [self logout];
    } else {
        [self showLoginAlertViewWithMessage:nil];
    }
}

- (void)showLoginAlertViewWithMessage:(NSString *)message {
    [self showLoginAlertViewWithMessage:message completionBlock:^(BOOL canceled, NSString *message) {
        if (!canceled) {
            if (message) {
                [self showLoginAlertViewWithMessage:message];
            } else {
                _loggedIn = YES;
                [self.tableView reloadData];
            }
        }
    }];
}

- (void)logout {
    AFHTTPClient* client = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:@"http://clien.net"]];
    [client getPath:@"/cs2/bbs/logout.php" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString* response = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        NSLog(@"%@", response);
        _loggedIn = NO;
        [self.tableView reloadData];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@", error);
    }];
}

- (BOOL)autoLogin {
    return ![[NSUserDefaults standardUserDefaults] boolForKey:SettingsManualLoginKey];
}

- (void)autoLoginChanged:(UISwitch*)sender {
    [[NSUserDefaults standardUserDefaults] setBool:!sender.on forKey:SettingsManualLoginKey];
}

- (BOOL)saveLogs {
    return [[NSUserDefaults standardUserDefaults] boolForKey:SettingsDebugKey];
}

- (void)saveLogsChanged:(UISwitch*)sender {
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
    Row* row = sections[indexPath.section].rows + indexPath.row;
    if (row->type == URLRow) {
        WebViewController* vc = [[WebViewController alloc] init];
        if (row->url) {
            NSString* url = [NSString stringWithUTF8String:row->url];
            if ([url hasSuffix:@"mb_id="]) { // fixme
                url = [url stringByAppendingString:[[NSUserDefaults standardUserDefaults] objectForKey:SettingsMemberIDKey] ?: @""];
            }
            vc.URL = [NSURL URLWithString:url];
        } else {
            vc.URL = [self logURL]; // fixme
        }
        [self.navigationController pushViewController:vc animated:YES];
    } else if (row->type == SimpleRow) {
        [self performSelector:NSSelectorFromString([NSString stringWithFormat:@"%sSelected:", row->url]) withObject:indexPath];
    }
}

@end
