//
//  OCWriteParser.h
//  OpenClien
//
//  Created by 안창범 on 2014. 6. 16..
//  Copyright (c) 2014년 안창범. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 CCL 플래그
 */
typedef enum : NSUInteger {
    OCCCLAttribution    = 1 << 0, /// CCL 사용
    OCCCLNonCommercial  = 1 << 1, /// 비영리
    OCCCLNoDerivs       = 1 << 2, /// 변경금지
    OCCCLShareAlike     = 1 << 3, /// 동일조건변경허락
} OCCCL;

/**
 글쓰기 페이지 파서
 */
@interface OCWriteParser : NSObject

/**
 오류 메시지
 */
@property (readonly, nonatomic) NSString *error;

/**
 카테고리
 */
@property (copy, nonatomic) NSString *category;

/**
 카테고리 목록
 */
@property (readonly, nonatomic) NSArray *categories;

/**
 제목
 */
@property (copy, nonatomic) NSString *title;

/**
 내용 (HTML)
 */
@property (copy, nonatomic) NSString *content;

/**
 CCL 플래그
 */
@property (nonatomic) NSUInteger CCLFlags;

/**
 링크
 */
@property (strong, nonatomic) NSArray *links;

/**
 첨부파일
 */
@property (readonly, nonatomic) NSArray *files;

/**
 최대 업로드 파일 갯수
 */
@property (readonly, nonatomic) int maxFiles;

/**
 업로드 최대용량
 */
@property (readonly, nonatomic) int maxUploadSize;

- (instancetype)initWithURL:(NSURL *)URL;

/**
 HTML 분석
 
 @param data HTML
 */
- (void)parse:(NSData *)data;

/**
 전송준비
 */
- (void)prepareSubmitWithBlock:(void(^)(NSURL *URL, NSDictionary *parameters))block;

/**
 전송결과 분석
 
 @param data 전송결과 HTML
 @param error 분석중 발생한 오류
 
 @return 오류 없이 분석했으면 YES, 아니면 NO
 */
- (BOOL)parseResult:(NSData *)data error:(NSError **)error;

@end
