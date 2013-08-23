//
//  Board.h
//  Clien
//
//  Created by 안창범 on 12. 8. 21..
//  Copyright (c) 2012년 안창범. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Board : NSManagedObject

@property (strong, nonatomic) NSString* title;
@property (strong, nonatomic) NSString* url;
@property (strong, nonatomic) NSNumber* section;
@property (strong, nonatomic) NSNumber* row;
@property (strong, nonatomic) NSNumber* hidden;

@end
