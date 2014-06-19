//
//  OCTextFieldTableViewCell.m
//  Example
//
//  Created by 안창범 on 2014. 6. 17..
//  Copyright (c) 2014년 Changbeom Ahn. All rights reserved.
//

#import "OCTextFieldTableViewCell.h"

@implementation OCTextFieldTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
