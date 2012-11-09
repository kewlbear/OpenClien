//
//  Board.h
//  Clien
//
//  Created by 안창범 on 12. 8. 21..
//  Copyright (c) 2012년 안창범. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Board : NSObject

@property (copy, nonatomic) NSString* title;
@property (strong, nonatomic) NSURL* URL;
@property (copy, nonatomic) NSString* src;

@end
