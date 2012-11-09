//
//  CommentCell.h
//  Clien
//
//  Created by 안창범 on 12. 8. 26..
//  Copyright (c) 2012년 안창범. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Comment.h"

@interface CommentCell : UITableViewCell

+ (CGFloat)heightForComment:(Comment*)comment tableView:(UITableView*)tableView;

@end
