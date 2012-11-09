//
//  ImageParagraph.h
//  Clien
//
//  Created by 안창범 on 12. 8. 27..
//  Copyright (c) 2012년 안창범. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Paragraph.h"

@interface ImageParagraph : NSObject <Paragraph> {
    NSURL* URL_;
    CGFloat y_;
    UIImageView* imageView;
}

- (id)initWithURL:(NSURL*)URL;

@end
