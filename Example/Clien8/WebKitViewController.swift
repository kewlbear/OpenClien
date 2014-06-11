//
//  WebKitViewController.swift
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

import UIKit
import WebKit

class WebKitViewController: UIViewController {

    var webView : WKWebView!
    
    init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        // Custom initialization
    }
    
    init(nibName: String!, bundle: NSBundle!) {
        super.init(nibName: nibName, bundle: bundle)
    }

    override func loadView() {
        super.loadView()
        
        let configuration = WKWebViewConfiguration()
        webView = WKWebView(frame: CGRectZero, configuration: configuration)
        view = webView
        
//        let options = NSLayoutFormatOptions(0)
//        let views = ["webView": webView]
//        let constraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|-[webView]-|", options: options, metrics: nil, views: views)
//        view.addConstraints(constraints)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let url = NSURL(string:"http://apple.com")
        let request = NSURLRequest(URL:url)
        webView.loadRequest(request)
        webView.scrollView.contentOffset = CGPointZero
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // #pragma mark - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue?, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

}
