//
//  OCComposeViewController.m
//  Example
//
// Copyright 2014 Changbeom Ahn
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

#import "OCComposeViewController.h"
#import "AFNetworking.h"
#import <OpenClien/OpenClien.h>
#import <OpenClien/OpenClien.h>
#import "OCTextFieldTableViewCell.h"
#import "OCWebViewTableViewCell.h"
#import "UIImageView+AFNetworking.h"

enum {
    kSectionTitle,
    kSectionLink,
    kSectionFile,
    kSectionContent
};

@implementation OCComposeViewController {
    OCWriteParser *_parser;
    UIBarButtonItem *_categoryItem;
    NSUInteger _maxLinks;
    NSArray *_files;
    CGFloat _contentHeight;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _contentHeight = 44;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData *data = [NSData dataWithContentsOfURL:_URL];
        _parser = [[OCWriteParser alloc] initWithURL:_URL];
        [_parser parse:data];
        NSString *title = _parser.title;
        NSString *content = _parser.content;
        NSUInteger CCLFlags = _parser.CCLFlags;
        _maxLinks = [_parser.links count];
        _parser.links = [_parser.links filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self.length > 0"]];
        [self updateFiles];
        int maxSize = _parser.maxUploadSize;
        NSLog(@"제목: %@, 내용: %@, CCL: %lu, 파일: %@ 최대 %lu개 %d바이트", title, content, (unsigned long) CCLFlags, _files, (unsigned long)[_parser.files count], maxSize);
        
        NSString *category = _parser.category;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (category) {
                _categoryItem = [[UIBarButtonItem alloc] initWithTitle:category style:UIBarButtonItemStylePlain target:self action:@selector(showCategories:)];
                self.navigationItem.rightBarButtonItems = @[self.navigationItem.rightBarButtonItem, _categoryItem];
            }
            
            [self.tableView reloadData];
            
            [[self webView].scrollView addObserver:self forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew context:NULL];
            [[self webView].scrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:NULL];
            
//            [[self webView] stringByEvaluatingJavaScriptFromString:@"document.body.focus()"];
        });
    });
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"contentSize"]) {
        [self.tableView beginUpdates];
        _contentHeight = [change[NSKeyValueChangeNewKey] CGSizeValue].height + .5;
        [self.tableView endUpdates];
    } else if ([keyPath isEqualToString:@"contentOffset"]) {
        static BOOL busy;
        if (!busy) {
            busy = YES;
            UIScrollView *scrollView = object;
            scrollView.contentOffset = CGPointZero;
            busy = NO;
        }
    }
}

- (void)updateFiles {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self.name != nil && self.deleted == NO"];
    _files = [_parser.files filteredArrayUsingPredicate:predicate];
}

- (UIWebView *)webView {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:kSectionContent];
    OCWebViewTableViewCell *cell = (OCWebViewTableViewCell *) [self.tableView cellForRowAtIndexPath:indexPath];
    return cell.webView;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == kSectionLink) {
        return [_parser.links count];
    } else if (section == kSectionFile) {
        return [_files count];
    } else {
        return 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == kSectionTitle) {
        OCTextFieldTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"text"];
        cell.textField.placeholder = @"제목";
        cell.textField.text = _parser.title;
        return cell;
    } else if (indexPath.section == kSectionLink) {
        OCTextFieldTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"text"];
        cell.textField.placeholder = @"링크";
        cell.textField.text = _parser.links[indexPath.row];
        return cell;
    } else if (indexPath.section == kSectionFile) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"file"];
        OCFile *file = _files[indexPath.row];
        cell.textLabel.text = file.name;
        if (!file.userInfo) {
            cell.detailTextLabel.text = file.size;
//            [cell.imageView setImageWithURL:file.URL]; // fixme
        } else {
            cell.detailTextLabel.text = nil;
            cell.imageView.image = file.userInfo;
        }
        return cell;
    } else if (indexPath.section == kSectionContent) {
        OCWebViewTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"web"];
//        cell.webView.keyboardDisplayRequiresUserAction = NO;
        cell.webView.scrollView.scrollEnabled = NO;
        
        if (_parser.content) {
            NSString *content = [NSString stringWithFormat:@"<div id=\"editor\" contentEditable=\"true\">%@</div>", _parser.content];
            [cell.webView loadHTMLString:content baseURL:nil];
        }
        return cell;
    } else {
        // fixme
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"file"];
        cell.textLabel.text = @"error";
        return cell;
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.section == kSectionLink || indexPath.section == kSectionFile ? UITableViewCellEditingStyleDelete : UITableViewCellEditingStyleNone;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == kSectionLink) {
        NSMutableArray *links = [_parser.links mutableCopy];
        [links removeObjectAtIndex:indexPath.row];
        _parser.links = links;
    } else if (indexPath.section == kSectionFile) {
        OCFile *file = _files[indexPath.row];
        file.deleted = YES;
        [self updateFiles];
    } else {
        return; // fixme
    }
    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == kSectionContent) {
        return _contentHeight;
    }
    return [super tableView:tableView heightForRowAtIndexPath:indexPath];
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

- (IBAction)dismiss:(id)sender {
    [[self webView].scrollView removeObserver:self forKeyPath:@"contentSize"];
    [[self webView].scrollView removeObserver:self forKeyPath:@"contentOffset"];

    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (IBAction)post:(id)sender {
    [self becomeFirstResponder];

    _parser.content = [[self webView] stringByEvaluatingJavaScriptFromString:@"document.getElementById('editor').innerHTML"];

    [_parser prepareSubmitWithBlock:^(NSURL *URL, NSDictionary *parameters) {
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        manager.responseSerializer = [AFHTTPResponseSerializer serializer];
        [manager POST:URL.absoluteString parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
            for (OCFile *file in _parser.files) {
                if (file.userInfo) {
                    UIImage *image = file.userInfo;
                    NSData *data = UIImageJPEGRepresentation(image, 1);
                    [formData appendPartWithFileData:data name:@"bf_file[]" fileName:file.name mimeType:@"image/jpeg"];
                } else {
                    [formData appendPartWithFileData:[NSData data] name:@"bf_file[]" fileName:@"" mimeType:@""];
                }
            }
        } success:^(AFHTTPRequestOperation *operation, id responseObject) {
            [_parser parseResult:responseObject];
            [self dismiss:self];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"%@", error);
            OCAlert(error.localizedDescription);
        }];
    }];
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

#pragma mark - Web view delegate

//- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
//    if ([request.URL.scheme isEqualToString:@"oc"]) {
//        _parser.content = [webView stringByEvaluatingJavaScriptFromString:@"document.body.innerHTML"];
//        return NO;
//    }
//    return YES;
//}

//- (void)webViewDidFinishLoad:(UIWebView *)webView {
//    [webView stringByEvaluatingJavaScriptFromString:@"document.getElementById('editor').focus()"];
//}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    NSLog(@"%@", error);
}

- (void)showCategories:(id)sender {
    UIActionSheet *sheet = [[UIActionSheet alloc] init];
    sheet.delegate = self;
    NSArray *categories = _parser.categories;
    for (NSString *category in categories) {
        [sheet addButtonWithTitle:category];
    }
    sheet.cancelButtonIndex = [sheet addButtonWithTitle:@"취소"];
    [sheet showFromBarButtonItem:sender animated:YES];
}

#pragma mark - Action sheet delegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex != actionSheet.cancelButtonIndex) {
        _parser.category = [actionSheet buttonTitleAtIndex:buttonIndex];
        _categoryItem.title = _parser.category;
    }
}

#pragma mark - Text field delegate

- (void)textFieldDidEndEditing:(UITextField *)textField {
    NSIndexPath *indexPath = [self indexPathForView:textField];
    if (indexPath.section == kSectionLink) {
        NSMutableArray *links = [_parser.links mutableCopy];
        links[indexPath.row] = textField.text;
    } else if (indexPath.section == kSectionTitle) {
        _parser.title = textField.text;
    } else {
        // fixme
    }
}

- (NSIndexPath *)indexPathForView:(UIView *)view {
    return [self.tableView indexPathForRowAtPoint:[view convertPoint:view.center toView:self.tableView]];
}

- (IBAction)addLink:(id)sender {
    NSInteger row = [self.tableView numberOfRowsInSection:kSectionLink];
    _parser.links = [_parser.links arrayByAddingObject:@""];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:kSectionLink];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (IBAction)addFile:(id)sender {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:NULL];
}

#pragma mark - Image picker controller delegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [self dismissViewControllerAnimated:YES completion:^{
        [_parser.files enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            OCFile *file = obj;
            if (!file.name || file.deleted) {
                file.name = @"image.jpg";
                file.deleted = NO;
                file.userInfo = info[UIImagePickerControllerOriginalImage];
                [self updateFiles];
                NSIndexSet *sections = [NSIndexSet indexSetWithIndex:kSectionFile];
                [self.tableView reloadSections:sections withRowAnimation:UITableViewRowAnimationAutomatic];
                *stop = YES;
            }
        }];
    }];
}

@end
