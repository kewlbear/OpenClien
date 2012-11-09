//
//  Paragraph.h
//  Clien
//
//  Created by 안창범 on 12. 8. 27..
//  Copyright (c) 2012년 안창범. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol Paragraph <NSObject>

@property (nonatomic) CGFloat y;
@property (readonly, nonatomic) UIView* view;
@property (readonly, nonatomic) CGFloat height;

@end
