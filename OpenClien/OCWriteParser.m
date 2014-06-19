//
//  OCWriteParser.m
//  OpenClien
//
//  Created by 안창범 on 2014. 6. 16..
//  Copyright (c) 2014년 안창범. All rights reserved.
//

#import "OCWriteParser.h"
#import "GDataXMLNode+OpenClien.h"
#import "OCFile.h"
#import "GTMNSString+HTML.h"

enum { CCLUnknown = 1 << (sizeof(OCCCL) * 8 - 1) };

@implementation OCWriteParser {
    GDataXMLDocument *_document;
    GDataXMLElement *_form;
    NSURL *_URL;
    NSArray *_files;
}

- (instancetype)initWithURL:(NSURL *)URL {
    self = [super init];
    if (self) {
        _URL = URL;
        _CCLFlags = CCLUnknown;
    }
    return self;
}

- (void)parse:(NSData *)data {
    NSError *error;
    _document = [[GDataXMLDocument alloc] initWithHTMLData:data error:&error];
    if (_document) {
        NSArray *forms = _document.rootElement[@"//form[@name='fwrite']"];
        if ([forms count]) {
            _form = forms[0];
        } else {
            // fixme 오류보고
            NSLog(@"%@", _document.rootElement);
        }
    } else {
        // fixme 오류보고
        NSLog(@"%@", error);
    }
}

- (NSString *)title {
    if (!_title) {
        NSArray *elements = _form[@".//input[@name='wr_subject']/@value"];
        _title = elements ? [elements[0] stringValue] : nil;
    }
    return _title;
}

- (NSString *)content {
    if (!_content) {
        NSArray *elements = _form[@".//textarea[@name='wr_content']"];
        _content = elements ? [[[elements[0] childAtIndex:0] XMLString] gtm_stringByUnescapingFromHTML] : nil;
    }
    return _content;
}

- (NSUInteger)CCLFlags {
    if (_CCLFlags == CCLUnknown) {
        _CCLFlags = 0;
        NSArray *by = _form[@".//select[@name='wr_ccl_by']/option[@selected]/@value"];
        if ([by count]) {
            if ([[by[0] stringValue] isEqualToString:@"by"]) {
                _CCLFlags |= OCCCLAttribution;
                NSArray *nc = _form[@".//select[@name='wr_ccl_nc']/option[@selected]/@value"];
                NSArray *nd = _form[@".//select[@name='wr_ccl_nd']/option[@selected]/@value"];
                if ([nc count] && [nd count]) {
                    if ([[nc[0] stringValue] isEqualToString:@"nc"]) {
                        _CCLFlags |= OCCCLNonCommercial;
                    }
                    NSString *value = [nd[0] stringValue];
                    if ([value isEqualToString:@"nd"]) {
                        _CCLFlags |= OCCCLNoDerivs;
                    } else if ([value isEqualToString:@"sa"]) {
                        _CCLFlags |= OCCCLShareAlike;
                    }
                }
            }
        } else {
            // fixme 오류보고
        }
    }
    return _CCLFlags;
}

- (NSArray *)files {
    if (!_files) {
        NSArray *scripts = _form[@".//table[@id='variableFiles']/following-sibling::script[1]"];
        if ([scripts count]) {
            NSString *script = [scripts[0] stringValue];
            NSError *error;
            // add_file("<input type='checkbox' name='bf_file_del[0]' value='1'><a href='./download.php?bo_table=park&wr_id=23682622&no=0&page=0' title='Down : 2, 2013-09-04 09:42:01'>photo.jpg(239.4K)</a> 파일 삭제");
            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"name='bf_file_del\\[(.*)]' value='1'><a href='(.*)' title='Down : (.*), (.*)'>(.*)\\((.*)\\)<" options:0 error:&error];
            if (regex) {
                NSMutableArray *files = [NSMutableArray array];
                [regex enumerateMatchesInString:script options:0 range:NSMakeRange(0, [script length]) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
                    NSLog(@"%@", result);
                    OCFile *file = [[OCFile alloc] init];
                    int index = [[script substringWithRange:[result rangeAtIndex:1]] intValue];
                    while ([files count] < index) {
                        [files addObject:[[OCFile alloc] init]];
                    }
                    file.URL = [NSURL URLWithString:[script substringWithRange:[result rangeAtIndex:2]] relativeToURL:_URL];
                    file.downloadCount = [[script substringWithRange:[result rangeAtIndex:3]] intValue];
                    file.date = [script substringWithRange:[result rangeAtIndex:4]];
                    file.name = [script substringWithRange:[result rangeAtIndex:5]];
                    file.size = [script substringWithRange:[result rangeAtIndex:6]];
                    [files addObject:file];
                }];
                int max = self.maxFiles;
                while ([files count] < max) {
                    [files addObject:[[OCFile alloc] init]];
                }
                _files = files;
            } else {
                NSLog(@"%@", error);
            }
        }
    }
    return _files;
}

- (int)maxFiles {
    int files = 0;
    [self parseFiles:&files size:NULL];
    return files;
}

- (void)parseFiles:(int*)files size:(int*)size {
    NSArray *divs = _form[@".//table[@id='variableFiles']/../div[1]"];
    if ([divs count]) {
        NSError *error;
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@".*(\\d+)개.*: (.*) " options:0 error:&error];
        if (regex) {
            NSString *text = [divs[0] stringValue];
            [regex enumerateMatchesInString:text options:0 range:NSMakeRange(0, [text length]) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
                if (files) {
                    *files = [[text substringWithRange:[result rangeAtIndex:1]] intValue];
                }
                if (size) {
                    *size = [[[text substringWithRange:[result rangeAtIndex:2]] stringByReplacingOccurrencesOfString:@"," withString:@""] intValue];
                }
                *stop = YES;
            }];
        }
    }
}

- (int)maxUploadSize {
    int size = 0;
    [self parseFiles:NULL size:&size];
    return size;
}

- (void)prepareSubmitWithBlock:(void (^)(NSURL *, NSDictionary *))block {
    NSURL *URL = [NSURL URLWithString:@"./write_update.php" relativeToURL:_URL];
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    NSArray *hiddens = _form[@".//input[@type='hidden']"];
    for (GDataXMLElement *hidden in hiddens) {
        NSString *value = [[hidden attributeForName:@"value"] stringValue];
        if (value) {
            parameters[[[hidden attributeForName:@"name"] stringValue]] = value;
        }
    }
    if ([self category]) {
        parameters[@"ca_name"] = [self category];
    }
    parameters[@"wr_subject"] = [self title];
    parameters[@"wr_content"] = [self content];
    
    if ([self CCLFlags] & OCCCLAttribution) {
        parameters[@"wr_ccl_by"] = @"by";
        if ([self CCLFlags] & OCCCLNonCommercial) {
            parameters[@"wr_ccl_nc"] = @"nc";
        }
        if ([self CCLFlags] & OCCCLNoDerivs) {
            parameters[@"wr_ccl_nd"] = @"nd";
        } else if ([self CCLFlags] & OCCCLShareAlike) {
            parameters[@"wr_ccl_nd"] = @"sa";
        }
    }
    
    for (int i = 0; i < [[self files] count]; ++i) {
        OCFile *file = [self files][i];
        if (file.deleted) {
            NSString *name = [NSString stringWithFormat:@"bf_file_del[%d]", i];
            parameters[name] = @"1";
        }
    }
    
    block(URL, parameters);
}

- (void)parseResult:(NSData *)data {
    NSError *error;
    GDataXMLDocument *document = [[GDataXMLDocument alloc] initWithHTMLData:data error:&error];
    if (document) {
        NSArray *scripts = document.rootElement[@"//script[1]"];
        if (scripts) {
            NSString *script = [scripts[0] stringValue];
            if ([script hasPrefix:@"alert("]) {
                NSLog(@"%@", [script componentsSeparatedByString:@"'"][1]);
                return;
            }
        }
        // fixme
        NSLog(@"%@", document.rootElement);
    } else {
        NSLog(@"%@", error);
    }
}

- (NSString *)category {
    if (!_category) {
        NSArray *scripts = _form[@"./following-sibling::script[2]"];
        if (scripts) {
            NSString *script = [scripts[0] stringValue];
            NSError *error;
            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"ca_name\\.value = \"(.*)\"" options:0 error:&error];
            if (regex) {
                [regex enumerateMatchesInString:script options:0 range:NSMakeRange(0, [script length]) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
                    _category = [script substringWithRange:[result rangeAtIndex:1]];
                    *stop = YES;
                }];
            } else {
                NSLog(@"%@", error);
            }
        } else {
            // fixme 오류보고
        }
    }
    return _category;
}

- (NSArray *)categories {
    NSArray *options = _form[@".//select[@name='ca_name']/option[position()>1]"];
    if ([options count]) {
        NSMutableArray *categories = [NSMutableArray array];
        for (GDataXMLElement *option in options) {
            [categories addObject:[option stringValue]];
        }
        return categories;
    }
    return nil;
}

- (NSArray *)links {
    if (!_links) {
        NSArray *inputs = _form[@".//input[contains(@name, 'wr_link')]"];
        if ([inputs count]) {
            NSMutableArray *links = [NSMutableArray array];
            for (GDataXMLElement *input in inputs) {
                [links addObject:[[input attributeForName:@"value"] stringValue]];
            }
            _links = links;
        }
    }
    return _links;
}

@end
