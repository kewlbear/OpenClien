//
//  BoardCell.h
//  Clien
//
//  Created by 안창범 on 12. 8. 24..
//  Copyright (c) 2012년 안창범. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BoardCell : UITableViewCell {
    UILabel* commentsLabel;
}

@property (nonatomic) int numberOfComments;

@end
