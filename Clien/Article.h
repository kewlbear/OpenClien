//
//  Article.h
//  Clien
//
//  Created by 안창범 on 12. 8. 21..
//  Copyright (c) 2012년 안창범. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Article : NSObject

@property (copy, nonatomic) NSString* title;
@property (strong, nonatomic) NSURL* URL;
@property (nonatomic) int numberOfComments;
@property (copy, nonatomic) NSString* name;
@property (copy, nonatomic) NSString* timestamp;
@property (nonatomic) int numberOfHits;
@property (strong, nonatomic) NSArray* content;

@end
