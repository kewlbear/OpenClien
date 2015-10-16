//
//  ClienTests.swift
//  OpenClien
//
//  Created by Changbeom Ahn on 2015. 10. 12..
//  Copyright © 2015년 안창범. All rights reserved.
//

import XCTest

class ClienTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        if isLoggedIn() {
            logOut()
        }
        logIn()
        XCTAssert(isLoggedIn())
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
}
