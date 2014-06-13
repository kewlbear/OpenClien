//
//  OCImageBoardViewController.m
//  Example
//
//  Created by 안창범 on 2014. 6. 2..
//  Copyright (c) 2014년 Changbeom Ahn. All rights reserved.
//

#import "OCImageBoardViewController.h"
#import <OpenClien/OpenClien.h>
#import "OCImageBoardCell.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "OCImageBoardHeader.h"

@interface OCImageBoardViewController ()

@end

@implementation OCImageBoardViewController
{
    OCBoardParser *_parser;
    NSArray *_articles;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    UICollectionViewFlowLayout *flowLayout = (UICollectionViewFlowLayout *) self.collectionViewLayout;
    flowLayout.headerReferenceSize = CGSizeMake(100, 40);
    
    [self reload];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return [_articles count];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    OCArticle *article = _articles[section];
    return [article.images count];
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    OCImageBoardHeader *header = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"header" forIndexPath:indexPath];
    OCArticle *article = _articles[indexPath.section];
    header.titleLabel.text = article.title;    
    return header;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    OCImageBoardCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    OCArticle *article = _articles[indexPath.section];
    [cell.imageView setImageWithURL:article.images[indexPath.item]];
    return cell;
}

- (void)setBoard:(OCBoard *)board
{
    _board = board;
    _parser = [[OCBoardParser alloc] initWithBoard:board];
}

- (void)reload
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData *data = [NSData dataWithContentsOfURL:_board.URL];
        _articles = [_parser parse:data];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.collectionView reloadData];
        });
    });
}

@end
