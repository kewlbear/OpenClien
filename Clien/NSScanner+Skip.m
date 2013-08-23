//
//  NSScanner+Skip.m
//  Clien
//
//  Created by 안창범 on 12. 8. 21..
//  Copyright (c) 2012년 안창범. All rights reserved.
//

#import "NSScanner+Skip.h"

@implementation NSScanner (Skip)

- (BOOL)skip:(NSString *)string {
    [self scanUpToString:string intoString:NULL];
    return [self scanString:string intoString:NULL];
}

@end
