//
//  ComposeViewController.h
//  Clien
//
//  Created by 안창범 on 13. 7. 16..
//  Copyright (c) 2013년 안창범. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^SuccessBlock)();

@class ComposeTextCell;

@interface ComposeViewController : UITableViewController

@property (strong, nonatomic) NSURL* url;
@property (weak, nonatomic) IBOutlet ComposeTextCell *textCell;
@property (strong, nonatomic) SuccessBlock successBlock;

@end
