//
//  OCLink.h
//  OpenClien
//
//  Created by 안창범 on 2014. 6. 11..
//  Copyright (c) 2014년 안창범. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 글 작성시 입력한 링크
 */
@interface OCLink : NSObject

/**
 URL
 */
@property (strong, nonatomic) NSURL *URL;

/**
 사용자에게 보여줄 텍스트
 */
@property (copy, nonatomic) NSString *text;

/**
 링크 클릭 수
 */
@property (nonatomic) int hitCount;

@end
