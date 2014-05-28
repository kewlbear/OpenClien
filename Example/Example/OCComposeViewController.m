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

@interface OCComposeViewController ()

@property (weak, nonatomic) IBOutlet UITextView *textView;

@end

@implementation OCComposeViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [_textView becomeFirstResponder];
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

- (IBAction)dismiss:(id)sender {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (IBAction)post:(id)sender {
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    NSString *url = [OCCommentParser URL].absoluteString;
    OCCommentParser *parser = [[OCCommentParser alloc] init];
    NSDictionary *parameters = [parser parametersForArticle:_article content:_textView.text];
    [manager POST:url parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSError *error;
        if ([parser parse:responseObject error:&error]) {
            // fixme
        } else {
            NSLog(@"%@", error);
            // fixme
            OCAlert(error.description);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@", error);
        // fixme
        OCAlert(error.description);
    }];
}

@end
