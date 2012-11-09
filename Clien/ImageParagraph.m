//
//  ImageParagraph.m
//  Clien
//
//  Created by 안창범 on 12. 8. 27..
//  Copyright (c) 2012년 안창범. All rights reserved.
//

#import "ImageParagraph.h"
#import "UIImageView+AFNetworking.h"

@implementation ImageParagraph

- (CGFloat)height {
    return 225;
}

- (id)initWithURL:(NSURL *)URL {
    self = [super init];
    if (self) {
        URL_ = URL;
    }
    return self;
}

- (void)setY:(CGFloat)y {
    if (imageView) {
        imageView.frame = CGRectOffset(imageView.frame, 0, y - y_);
    }
    y_ = y;
}

- (CGFloat)y {
    return y_;
}

- (UIView*)view {
    if (!imageView) {
        imageView = [[UIImageView alloc] initWithImage:nil];
        imageView.frame = CGRectMake(10, self.y, 300, 225);
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        [imageView setImageWithURLRequest:[NSURLRequest requestWithURL:URL_]
                         placeholderImage:[[UIImage alloc] init]
                                  success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                      //
                                  }
                                  failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                                      NSLog(@"%s: %@", __func__, error);
                                  }];
    }
    return imageView;
}

@end
