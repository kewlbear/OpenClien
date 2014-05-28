//
//  Board.h
//  Example
//
//  Created by 안창범 on 2014. 5. 20..
//  Copyright (c) 2014년 Changbeom Ahn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Board : NSManagedObject

@property (nonatomic, retain) NSNumber * order;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSData * data;

@end
