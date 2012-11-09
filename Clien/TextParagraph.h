//
//  TextParagraph.h
//  Clien
//
//  Created by 안창범 on 12. 8. 27..
//  Copyright (c) 2012년 안창범. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Paragraph.h"

@interface TextParagraph : NSObject <Paragraph> {
    NSString* text;
    CGFloat y_;
    UILabel* label;
}

- (id)initWithString:(NSString*)string;

@end
