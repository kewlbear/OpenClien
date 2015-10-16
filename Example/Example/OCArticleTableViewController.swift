//
//  OCArticleTableViewController.swift
//  Example
//
//  Created by Changbeom Ahn on 2015. 10. 16..
//  Copyright © 2015년 Changbeom Ahn. All rights reserved.
//

import Foundation

extension OCArticleTableViewController {
    func search(memberID: String) {
        let boardController = storyboard?.instantiateViewControllerWithIdentifier("board") as! OCBoardTableViewController
        let searchController = UISearchController(searchResultsController: boardController)
        boardController.searchController = searchController
        searchController.searchBar.text = memberID
        boardController.board = article.URL.board()
        presentViewController(searchController, animated: true, completion: nil)
    }
}