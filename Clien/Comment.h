//
//  Comment.h
//  Clien
//
//  Created by 안창범 on 12. 8. 25..
//  Copyright (c) 2012년 안창범. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Comment : NSObject

@property (copy, nonatomic) NSString* user;
@property (copy, nonatomic) NSString* content;
@property (copy, nonatomic) NSString* timestamp;
@property (nonatomic) BOOL nested;

@end
