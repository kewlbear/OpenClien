//
//  ComposeViewController.h
//  Clien
//
//  Created by 안창범 on 13. 7. 16..
//  Copyright (c) 2013년 안창범. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ComposeViewController : UIViewController<UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;

@end
