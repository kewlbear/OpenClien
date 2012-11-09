//
//  CommentCell.m
//  Clien
//
//  Created by 안창범 on 12. 8. 26..
//  Copyright (c) 2012년 안창범. All rights reserved.
//

#import "CommentCell.h"

enum {
    NAME_HEIGHT = 16
};

@implementation CommentCell

+ (CGFloat)heightForComment:(Comment *)comment tableView:(UITableView *)tableView {
    static UILabel* label;
    if (!label) {
        label = [[UILabel alloc] initWithFrame:CGRectZero];
        [self configureContentLabel:label];
    }
    label.text = comment.content;
    return NAME_HEIGHT + 10 + [label sizeThatFits:CGSizeMake(tableView.bounds.size.width - comment.nested * 10 - 20, 0)].height + 10;   // TODO: change indent calculation
}

+ (void)configureContentLabel:(UILabel*)label {
    label.font = [UIFont systemFontOfSize:14];
    label.numberOfLines = 0;
    label.lineBreakMode = UILineBreakModeCharacterWrap;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [CommentCell configureContentLabel:self.textLabel];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.detailTextLabel.font = [UIFont systemFontOfSize:NAME_HEIGHT - 2];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.textLabel.frame = UIEdgeInsetsInsetRect(self.contentView.bounds, UIEdgeInsetsMake(5 + NAME_HEIGHT + 10, self.indentationLevel * self.indentationWidth + 10, 5, 10));
    self.detailTextLabel.frame = CGRectMake(self.indentationLevel * self.indentationWidth + 10, 5, self.contentView.bounds.size.width - 20, NAME_HEIGHT);
    self.imageView.frame = CGRectMake(self.indentationLevel * self.indentationWidth + 10, 5, 60, NAME_HEIGHT);
}

- (void)prepareForReuse {
    self.detailTextLabel.text = nil;
    self.imageView.image = nil;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
