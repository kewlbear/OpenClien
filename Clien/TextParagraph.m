//
//  TextParagraph.m
//  Clien
//
//  Created by 안창범 on 12. 8. 27..
//  Copyright (c) 2012년 안창범. All rights reserved.
//

#import "TextParagraph.h"
#import "GTMNSString+HTML.h"

static CGFloat TEXT_WIDTH = 300;

@implementation TextParagraph

+ (void)configureContentLabel:(UILabel*)label {
    label.font = [UIFont systemFontOfSize:15];
    label.numberOfLines = 0;
    label.lineBreakMode = UILineBreakModeCharacterWrap;
}

+ (CGFloat)heightForText:(NSString*)text {
    UILabel* label;
    if (!label) {
        label = [[UILabel alloc] initWithFrame:CGRectZero];
        [self configureContentLabel:label];
    }
    label.text = text;
    return [label sizeThatFits:CGSizeMake(TEXT_WIDTH, 0)].height;
}

- (id)initWithString:(NSString*)string {
    self = [super init];
    if (self) {
        text = string.gtm_stringByUnescapingFromHTML;
    }
    return self;
}

- (void)setY:(CGFloat)y {
    if (label) {
        label.frame = CGRectOffset(label.frame, 0, y - y_);
    }
    y_ = y;
}

- (CGFloat)y {
    return y_;
}

- (UIView*)view {
    if (!label) {
        label = [[UILabel alloc] initWithFrame:CGRectMake(10, self.y, TEXT_WIDTH, 0)];
        [TextParagraph configureContentLabel:label];
        label.text = text;
        [label sizeToFit];
    }
    return label;
}

- (CGFloat)height {
    return [TextParagraph heightForText:text];
}

@end
