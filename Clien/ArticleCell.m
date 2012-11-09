//
//  ArticleCell.m
//  Clien
//
//  Created by 안창범 on 12. 8. 26..
//  Copyright (c) 2012년 안창범. All rights reserved.
//

#import "ArticleCell.h"
#import "Paragraph.h"

@implementation ArticleCell

+ (CGFloat)heightForArticle:(Article *)article tableView:(UITableView *)tableView {
    CGFloat height = 0;
    for (id<Paragraph> paragraph in article.content) {
        height += paragraph.height;
    }
    return height + 10;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
}

- (void)setArticle:(Article *)article {
    CGFloat y = 5;
    for (id<Paragraph> paragraph in article.content) {
        paragraph.y = y;
        [self.contentView addSubview:paragraph.view];
        y += paragraph.height;
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
