//
//  OCImageBoardViewController.h
//  Example
//
//  Created by 안창범 on 2014. 6. 2..
//  Copyright (c) 2014년 Changbeom Ahn. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OCBoard;

@interface OCImageBoardViewController : UICollectionViewController <UICollectionViewDelegateFlowLayout>

@property (strong, nonatomic) OCBoard *board;

@end
