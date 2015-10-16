//
//  OCBoardTableViewController.swift
//  Example
//
//  Created by Changbeom Ahn on 2015. 10. 13..
//  Copyright © 2015년 Changbeom Ahn. All rights reserved.
//

import Foundation

extension OCBoardTableViewController: UISearchControllerDelegate {
    func setupSearch() {
        if searchController != nil {
            searchController.delegate = self
            setSearchField(3, title: "회원아이디") // TODO: enum?
            return
        }
        
        let searchResultsController = UITableViewController(style: .Plain)
        searchResultsController.tableView.dataSource = self
        searchResultsController.tableView.delegate = self
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: "reload", forControlEvents: .ValueChanged)
        searchResultsController.refreshControl = refreshControl

        searchController = UISearchController(searchResultsController: searchResultsController)
        searchController.delegate = self
        
        definesPresentationContext = true
    }
    
    @IBAction func activateSearch(sender: AnyObject) {
        presentViewController(searchController, animated: true, completion: nil)
    }
    
    func showSearchFieldView(sender: AnyObject) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        let titles = ["제목", "내용", "제목+내용", "회원아이디", "회원아이디(코)", "이름", "이름(코)"]
        let handler = { (action: UIAlertAction) -> Void in
            self.setSearchField(actionSheet.actions.indexOf(action)!, title: action.title)
        }
        for title in titles {
            actionSheet.addAction(UIAlertAction(title: title, style: .Default, handler: handler))
        }
        actionSheet.addAction(UIAlertAction(title: "취소", style: .Cancel, handler: nil))
        presentViewController(actionSheet, animated: true, completion: nil)
    }
    
    func searchMember(memberID: String) {
        // TODO: ...
    }
}