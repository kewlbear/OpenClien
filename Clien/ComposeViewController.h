//
//  ComposeViewController.h
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

#import <UIKit/UIKit.h>

typedef void (^SuccessBlock)();

@interface ComposeViewController : UITableViewController <UIPickerViewDataSource, UIPickerViewDelegate, UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (strong, nonatomic) NSURL* url;
@property (strong, nonatomic) SuccessBlock successBlock;
@property (strong, nonatomic) void (^loadBlock)(ComposeViewController* vc);
@property (strong, nonatomic) NSDictionary* extraParameters;
@property (strong, nonatomic) NSArray* categories;
@property (assign, nonatomic) BOOL isComment;
@property (strong, nonatomic) NSArray* attachments;

@property (weak, nonatomic) IBOutlet UITextField *titleField;
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UIButton *imageButton;
@property (weak, nonatomic) IBOutlet UITextField *categoryField;
@property (strong, nonatomic) IBOutletCollection(UITextField) NSArray *linkFields;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textViewRightMargin;

- (IBAction)attach:(id)sender;

@end

@interface UIViewController (Compose)

- (void)presentComposeViewControllerWithBlock:(void (^)(ComposeViewController* vc))block;

@end