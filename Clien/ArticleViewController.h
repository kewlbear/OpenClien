//
//  ArticleViewController.h
//  Clien
//
//  Created by 안창범 on 12. 8. 21..
//  Copyright (c) 2012년 안창범. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ArticleViewController : UIViewController <NSURLConnectionDataDelegate> {
    NSMutableData* receivedData;
}

@property (copy, nonatomic) NSString* href;
@property (weak, nonatomic) UITextView* textView;

@end
