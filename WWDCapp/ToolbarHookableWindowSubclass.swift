//
//  ToolbarHookableWindowSubclass.swift
//  WWDC
//
//  Created by David Roberts on 01/07/2015.
//  Copyright © 2015 Dave Roberts. All rights reserved.
//

import Foundation
import Cocoa

class ToolbarHookableWindowSubclass : NSWindowController {
	
	@IBOutlet weak var yearSeletor: NSPopUpButton!
	@IBOutlet weak var forceRefreshButton: NSButton!
	@IBOutlet weak var yearFetchIndicator: NSProgressIndicator!
	@IBOutlet weak var stopFetchButton: NSButton!
	@IBOutlet weak var searchField: NSSearchField!
	@IBOutlet weak var combineProgressLabel: NSTextField!
    @IBOutlet weak var combinePDFIndicator: NSProgressIndicator!
    @IBOutlet weak var combinePDFButton: NSButton!
}