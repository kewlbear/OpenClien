//
//  ArticleViewController.h
//  Clien
//
//  Created by 안창범 on 12. 8. 21..
//  Copyright (c) 2012년 안창범. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Article.h"

@interface ArticleViewController : UITableViewController <NSURLConnectionDataDelegate> {
    NSMutableData* receivedData;
    Article* article;
    NSArray* comments;
}

@property (strong, nonatomic) NSURL* URL;

@end
