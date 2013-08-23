//
//  BoardViewController.h
//  Clien
//
//  Created by 안창범 on 12. 8. 21..
//  Copyright (c) 2012년 안창범. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BoardViewController : UITableViewController <UISearchDisplayDelegate, UISearchBarDelegate> {
    NSMutableArray* articles;
}

@property (strong, nonatomic) NSURL* URL;

@end
