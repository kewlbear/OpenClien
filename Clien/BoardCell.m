//
//  BoardCell.m
//  Clien
//
// Copyright 2013 Changbeom Ahn
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "BoardCell.h"
#import <QuartzCore/QuartzCore.h>

@implementation BoardCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.textLabel.numberOfLines = 0;
        self.textLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        self.textLabel.font = [UIFont systemFontOfSize:14];
        
        commentsLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        commentsLabel.textAlignment = NSTextAlignmentCenter;
        commentsLabel.font = [UIFont boldSystemFontOfSize:12];
        commentsLabel.textColor = [UIColor whiteColor];
//        commentsLabel.shadowColor = [UIColor darkGrayColor];
        CALayer* layer = commentsLabel.layer;
        layer.cornerRadius = 8;
        [self.contentView addSubview:commentsLabel];
        
        self.detailTextLabel.font = [UIFont systemFontOfSize:13];
        self.detailTextLabel.textAlignment = NSTextAlignmentCenter;
        self.detailTextLabel.textColor = [UIColor darkGrayColor];
        self.detailTextLabel.adjustsFontSizeToFitWidth = YES;
//        self.detailTextLabel.shadowColor = [UIColor darkGrayColor];
        
        self.clipsToBounds = YES;
    }
    return self;
}

- (void)layoutSubviews {
    self.imageView.frame = CGRectZero;
    
    [super layoutSubviews];
    
    if (_isImageBoard) {
        self.imageView.frame = self.bounds;
        CGSize size = self.contentView.bounds.size;
        size.width -= 20;
        size = [self.textLabel sizeThatFits:size];
        self.textLabel.frame = CGRectMake(10, self.contentView.bounds.size.height - size.height - 10, size.width, size.height);
        self.textLabel.backgroundColor = [UIColor colorWithWhite:1 alpha:.5];
    } else {
        self.imageView.frame = UIEdgeInsetsInsetRect(self.contentView.bounds, UIEdgeInsetsMake(3, self.contentView.bounds.size.width - 70, self.contentView.bounds.size.height - 19, 10));// CGRectMake(10, 14, 60, 16);
        self.textLabel.frame = UIEdgeInsetsInsetRect(self.contentView.bounds, UIEdgeInsetsMake(5, 10, 5, 80));
        CGFloat dx = (self.imageView.frame.size.width - [commentsLabel sizeThatFits:CGSizeZero].width) / 2 - 8;
        commentsLabel.frame = UIEdgeInsetsInsetRect(self.contentView.bounds, UIEdgeInsetsMake(25, self.contentView.bounds.size.width - 70 + dx, 3, 10 + dx));
        self.detailTextLabel.frame = self.imageView.frame;
    }
}

- (void)setNumberOfComments:(int)numberOfComments {
    if (numberOfComments) {
        commentsLabel.text = [NSString stringWithFormat:@"%d", numberOfComments];
        commentsLabel.backgroundColor = [UIColor colorWithRed:1 green:0 blue:0 alpha:numberOfComments / 100.f * .8f + .2f];
    } else {
        commentsLabel.text = nil;
    }
    commentsLabel.hidden = numberOfComments < 1;
}

- (void)prepareForReuse {
    self.imageView.image = nil;
    self.detailTextLabel.text = nil;
}

- (void)setIsImageBoard:(BOOL)isImageBoard {
    _isImageBoard = isImageBoard;
    if (isImageBoard && ![self respondsToSelector:@selector(separatorInset)]) { // iOS 6.x
        self.clipsToBounds = YES;
    }
}

@end
