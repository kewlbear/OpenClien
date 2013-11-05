//
//  ComposeViewController.m
//  Clien
//
// Copyright 2013 Changbeom Ahn
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

#import "ComposeViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "AFHTTPClient.h"
#import "NSScanner+Skip.h"

@interface ComposeViewController ()

@property (strong, nonatomic) UIImage* image;

@end

@implementation ComposeViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismiss)];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"보내기" style:UIBarButtonItemStylePlain target:self action:@selector(submit:)];
    }
    return self;
}

- (void)submit:(UIBarButtonItem*)sender {
    sender.enabled = NO;
    AFHTTPClient* httpClient = [AFHTTPClient clientWithBaseURL:_url];
    NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
    NSArray* array = [_url.baseURL.query componentsSeparatedByString:@"&"];
    for (NSString* parameter in array) {
        NSArray* nameValue = [parameter componentsSeparatedByString:@"="];
//        NSLog(@"%@", nameValue);
        parameters[nameValue[0]] = nameValue[1];
    }
    parameters[@"wr_content"] = _textView.text;
    if (_extraParameters) {
        [parameters addEntriesFromDictionary:_extraParameters];
    }
    if (!_isComment) {
        parameters[@"wr_subject"] = _titleField.text;
        parameters[@"ca_name"] = _categoryField.text;
        parameters[@"wr_link1"] = ((UITextField*) _linkFields[0]).text;
        parameters[@"wr_link2"] = ((UITextField*) _linkFields[1]).text;
        NSMutableURLRequest* request = [httpClient multipartFormRequestWithMethod:@"post" path:@"" parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
            if (_image) {
                NSData* data = UIImageJPEGRepresentation(_image, 1);
                [formData appendPartWithFileData:data name:@"bf_file[]" fileName:@"photo.jpg" mimeType:@"image/jpeg"]; // fixme filename, mime type
            }
        }];
        AFHTTPRequestOperation* operation = [httpClient HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
            [self handleResponse:responseObject];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [self handleError:error];
        }];
        [httpClient enqueueHTTPRequestOperation:operation];
    } else {
        [httpClient postPath:@"" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
            [self handleResponse:responseObject];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [self handleError:error];
        }];
    }
}

- (void)handleResponse:(id)responseObject {
    // fixme
    NSString* response = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
    NSLog(@"%@", response);
    self.navigationItem.rightBarButtonItem.enabled = YES;
    // fixme merge message handling
    NSScanner* scanner = [NSScanner scannerWithString:response];
    if ([scanner skip:@"alert('"]) {
        NSString* message;
        [scanner scanUpToString:@"'" intoString:&message];
        message = [message stringByReplacingOccurrencesOfString:@"\\n" withString:@" "];
        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:nil message:message delegate:nil cancelButtonTitle:nil otherButtonTitles:@"확인", nil];
        [alertView show];
    } else {
        if (_successBlock) {
            _successBlock();
        }
    }
}

- (void)handleError:(NSError*)error {
    NSLog(@"%@", error);
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:nil message:error.localizedDescription delegate:nil cancelButtonTitle:nil otherButtonTitles:@"확인", nil];
    [alertView show];
}

- (void)dismiss {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationController.view.superview.layer.cornerRadius = 5;
    if (_isComment) {
        _imageButton.hidden = YES;
        _textViewRightMargin.constant = -70;
        _textView.scrollIndicatorInsets = UIEdgeInsetsZero;
    }
    [_textView becomeFirstResponder];
    
    UIPickerView* pickerView = [[UIPickerView alloc] init];
    pickerView.dataSource = self;
    pickerView.delegate = self;
    _categoryField.inputView = pickerView;
    
    if (_loadBlock) {
        _loadBlock(self);
    }

    [self updateImageButton];
}

- (void)updateImageButton {
    [_imageButton setBackgroundImage:_image forState:UIControlStateNormal];
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return _categories.count;
}

- (NSString*)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return _categories[row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    _categoryField.text = _categories[row];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        if (YES || animated) // fixme
        {
            CATransition *slide = [CATransition animation];
            
            slide.type = kCATransitionPush;
            slide.subtype = kCATransitionFromTop;
            slide.duration = 0.4;
            slide.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
            
            slide.removedOnCompletion = YES;
            
            [self.navigationController.view.superview.layer addAnimation:slide forKey:@"slidein"];
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self shouldShowRowAtIndexPath:indexPath]) {
        return [super tableView:tableView heightForRowAtIndexPath:indexPath];
    }
    return 0;
}

- (BOOL)shouldShowRowAtIndexPath:(NSIndexPath*)indexPath {
    if (_isComment) {
        return indexPath.row == 1;
    }
    return indexPath.row != 2 || _categories.count;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell* cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    cell.hidden = ![self shouldShowRowAtIndexPath:indexPath];
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    [_textView becomeFirstResponder];
}

- (void)setCategories:(NSArray*)categories {
    _categories = categories;
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)attach:(UIButton*)sender {
    UIActionSheet* actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"취소" destructiveButtonTitle:@"삭제" otherButtonTitles:@"기존 항목 선택", nil];
    [actionSheet showFromRect:sender.bounds inView:sender animated:YES];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == actionSheet.destructiveButtonIndex) {
        self.image = nil;
    } else if (buttonIndex == actionSheet.firstOtherButtonIndex) {
        UIImagePickerController* picker = [[UIImagePickerController alloc] init];
        picker.delegate = self;
        [self presentViewController:picker animated:YES completion:NULL];
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    self.image = [info objectForKey:UIImagePickerControllerOriginalImage];
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)setImage:(UIImage *)image {
    _image = image;
    [self updateImageButton];
}

@end

@implementation UIViewController (Compose)

- (void)presentComposeViewControllerWithBlock:(void (^)(ComposeViewController *))block {
    NSString* identifier;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        identifier = @"ComposePhone";
    } else {
        identifier = @"ComposePad";
    }
    UIViewController* container = [[UIStoryboard storyboardWithName:@"SharedStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:identifier];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        self.navigationController.modalPresentationStyle = UIModalPresentationCurrentContext;
    } else {
        container.modalPresentationStyle = UIModalPresentationFormSheet;
    }
    [self presentViewController:container animated:YES completion:^{
        UINavigationController* nc;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            nc = container.childViewControllers[0];
            if ([self respondsToSelector:@selector(edgesForExtendedLayout)]) {
                // prevent compose view underlapping status bar
                for (NSLayoutConstraint* constraint in container.view.constraints) {
                    if (constraint.firstAttribute == NSLayoutAttributeTop) {
                        constraint.constant += 20;
                        break;
                    }
                }
            }
            // prevent navigation bar extending under non-existent status bar :-(
            nc.view.frame = UIEdgeInsetsInsetRect(nc.view.frame, UIEdgeInsetsMake(1, 0, -1, 0));
        } else {
            nc = (UINavigationController*) container;
        }
        ComposeViewController* vc = nc.viewControllers[0];
        if (block) {
            block(vc);
        }
    }];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        container.view.superview.bounds = CGRectMake(0, 0, 300, 225);
    }
}

@end