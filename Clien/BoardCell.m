//
//  BoardCell.m
//  Clien
//
//  Created by 안창범 on 12. 8. 24..
//  Copyright (c) 2012년 안창범. All rights reserved.
//

#import "BoardCell.h"

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
        commentsLabel.font = [UIFont systemFontOfSize:12];
        [self.contentView addSubview:commentsLabel];
        
        self.detailTextLabel.font = [UIFont systemFontOfSize:15];
        self.detailTextLabel.textAlignment = UITextAlignmentCenter;
        self.detailTextLabel.textColor = [UIColor blackColor];
        self.detailTextLabel.adjustsFontSizeToFitWidth = YES;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.imageView.frame = CGRectMake(10, 14, 60, 16);
    self.textLabel.frame = UIEdgeInsetsInsetRect(self.contentView.bounds, UIEdgeInsetsMake(5, 80, 5, 30));
    commentsLabel.frame = UIEdgeInsetsInsetRect(self.contentView.bounds, UIEdgeInsetsMake(5, self.contentView.bounds.size.width - 30, 5, 0));
    self.detailTextLabel.frame = CGRectMake(10, 17, 60, 16);
}

- (void)setNumberOfComments:(int)numberOfComments {
    commentsLabel.text = [NSString stringWithFormat:@"%d", numberOfComments];
}

- (void)prepareForReuse {
    self.imageView.image = nil;
    self.detailTextLabel.text = nil;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
