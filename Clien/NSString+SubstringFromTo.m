//
//  NSString+SubstringFromTo.m
//  Clien
//
//  Created by 안창범 on 12. 8. 21..
//  Copyright (c) 2012년 안창범. All rights reserved.
//

#import "NSString+SubstringFromTo.h"

@implementation NSString (SubstringFromTo)

- (NSString*)substringFrom:(NSString*)from to:(NSString*)to {
    NSRange fromRange = [self rangeOfString:from];
    if (fromRange.location == NSNotFound) {
        return nil;
    }
    NSRange toRange = [self rangeOfString:to options:0 range:NSMakeRange(fromRange.location + fromRange.length, self.length - fromRange.location - fromRange.length)];
    if (toRange.location == NSNotFound) {
        return nil;
    }
    return [self substringWithRange:NSMakeRange(fromRange.location + fromRange.length, toRange.location - fromRange.location - fromRange.length)];
}

@end
