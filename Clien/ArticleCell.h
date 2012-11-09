//
//  ArticleCell.h
//  Clien
//
//  Created by 안창범 on 12. 8. 26..
//  Copyright (c) 2012년 안창범. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Article.h"

@interface ArticleCell : UITableViewCell

+ (CGFloat)heightForArticle:(Article*)article tableView:(UITableView*)tableView;

- (void)setArticle:(Article*)article;

@end
