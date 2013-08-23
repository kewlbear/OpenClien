//
//  BoardCell.m
//  Clien
//
//  Created by 안창범 on 12. 8. 24..
//  Copyright (c) 2012년 안창범. All rights reserved.
//

#import "BoardCell.h"
#import <QuartzCore/QuartzCore.h>

@implementation BoardCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.textLabel.numberOfLines = 0;
        self.textLabel.lineBreakMode = UILineBreakModeTailTruncation;
        self.textLabel.font = [UIFont systemFontOfSize:14];
        
        commentsLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        commentsLabel.textAlignment = UITextAlignmentCenter;
        commentsLabel.font = [UIFont boldSystemFontOfSize:12];
        commentsLabel.textColor = [UIColor whiteColor];
//        commentsLabel.shadowColor = [UIColor darkGrayColor];
        CALayer* layer = commentsLabel.layer;
        layer.cornerRadius = 8;
        [self.contentView addSubview:commentsLabel];
        
        self.detailTextLabel.font = [UIFont systemFontOfSize:13];
        self.detailTextLabel.textAlignment = UITextAlignmentCenter;
        self.detailTextLabel.textColor = [UIColor darkGrayColor];
        self.detailTextLabel.adjustsFontSizeToFitWidth = YES;
//        self.detailTextLabel.shadowColor = [UIColor darkGrayColor];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.imageView.frame = UIEdgeInsetsInsetRect(self.contentView.bounds, UIEdgeInsetsMake(3, self.contentView.bounds.size.width - 70, self.contentView.bounds.size.height - 19, 10));// CGRectMake(10, 14, 60, 16);
    self.textLabel.frame = UIEdgeInsetsInsetRect(self.contentView.bounds, UIEdgeInsetsMake(5, 10, 5, 80));
    CGFloat dx = (self.imageView.frame.size.width - [commentsLabel sizeThatFits:CGSizeZero].width) / 2 - 8;
    commentsLabel.frame = UIEdgeInsetsInsetRect(self.contentView.bounds, UIEdgeInsetsMake(25, self.contentView.bounds.size.width - 70 + dx, 3, 10 + dx));
    self.detailTextLabel.frame = self.imageView.frame;
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

@end
