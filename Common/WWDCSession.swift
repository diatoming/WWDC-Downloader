//
//  WWDCSession.swift
//  WWDC
//
//  Created by David Roberts on 15/06/2015.
//  Copyright © 2015 Dave Roberts. All rights reserved.
//

import Foundation
import Cocoa

class TranscriptInfo : NSObject, NSCoding {
	
	let timeStamp : Double
	let caption : String

	init(tuple : (Double, String)) {
		self.timeStamp = tuple.0
		self.caption = tuple.1
	}
	
	required init(coder aDecoder: NSCoder) {
		let timestamp = aDecoder.decodeDoubleForKey("timeStamp")
		self.timeStamp  = timestamp
		let caption = aDecoder.decodeObjectForKey("caption") as! String
		self.caption = caption
		super.init()
	}
	
	func encodeWithCoder(aCoder: NSCoder) {
		aCoder.encodeDouble(self.timeStamp, forKey:"timeStamp")
		aCoder.encodeObject(self.caption, forKey: "caption")
	}
}


func ==(lhs: WWDCSession, rhs: WWDCSession)-> Bool {
    return lhs.sessionYear == rhs.sessionYear && lhs.sessionID == rhs.sessionID
}

@objc class WWDCSession : NSObject, NSCoding {
	
    let title : String
    let sessionID : String
    let sessionYear : WWDCYear
	
	var displayName : String {
		get {
			return sessionYear.description+" - "+sessionID+" - "+title
		}
	}

    var isInfoFetchComplete = false
	
    var streamingURL : NSURL?

    var hdFile : FileInfo?
    var sdFile : FileInfo?
    var pdfFile : FileInfo?

    var sampleCodeArray : [FileInfo]
	
	// ASCIIwwdc fetchedInfo
	var sessionDescription : String?
	var sessionTrack : String?
	var fullTranscriptPrettyPrint : String?
	var transcript : [TranscriptInfo]?
	var transcriptHTMLFormatted : String?
    
    var hasAnyDownloadedFiles : Bool {
        get {
            if hdFile?.isFileAlreadyDownloaded == true {
                return true
            }
            
            if sdFile?.isFileAlreadyDownloaded == true {
                return true
            }
            
            if pdfFile?.isFileAlreadyDownloaded == true {
                return true
            }
            
            for sample in sampleCodeArray {
                if sample.isFileAlreadyDownloaded == true {
                    return true
                }
            }
            return false
        }
    }
	
	init(sessionID: String, title: String, year: WWDCYear) {
        
        self.title = title
        self.sessionID = sessionID
        self.sessionYear = year

        sampleCodeArray = []
	}
    
    func deleteDownloadedFiles() {
		
		var urlsToDelete = [NSURL]()
		
        if hdFile?.isFileAlreadyDownloaded == true {
            if let url = hdFile?.localFileURL {
				urlsToDelete.append(url)
            }
        }
        
        if sdFile?.isFileAlreadyDownloaded == true {
            if let url = sdFile?.localFileURL {
				urlsToDelete.append(url)
            }
        }
        
        if pdfFile?.isFileAlreadyDownloaded == true {
            if let url = pdfFile?.localFileURL {
				urlsToDelete.append(url)
            }
        }
        
        for sample in sampleCodeArray {
            if sample.isFileAlreadyDownloaded == true {
                if let url = sample.localFileURL {
					urlsToDelete.append(url)
                }
            }
        }
		
		for url in urlsToDelete {
			do {
				try NSFileManager.defaultManager().removeItemAtURL(url)
			}
			catch {
				print(error)
			}
		}
		
//		dispatch_async(dispatch_get_main_queue()) {		
//			NSWorkspace.sharedWorkspace().recycleURLs(urlsToDelete) { (dictionary, error) -> Void in
//				print(dictionary)
//				print(error)
//				print("Moved to trash")
//			}
//		}
	}
	    
    func forceCheckIfFilesExistLocally() {
        if let sdFile = sdFile {
            sdFile.forceCheckIfFileExists()
        }
        if let hdFile = hdFile {
            hdFile.forceCheckIfFileExists()
        }
        if let pdfFile = pdfFile {
            pdfFile.forceCheckIfFileExists()
        }
        for sample in sampleCodeArray {
            sample.forceCheckIfFileExists()
        }
    }

	
	required init(coder aDecoder: NSCoder) {
		self.title  = aDecoder.decodeObjectForKey("title") as! String
		self.sessionID  = aDecoder.decodeObjectForKey("sessionID") as! String
		let yearString = aDecoder.decodeObjectForKey("sessionYear") as! String
		switch yearString {
		case "2015":
			self.sessionYear = .WWDC2015
		case "2014":
			self.sessionYear = .WWDC2014
		case "2013":
			self.sessionYear = .WWDC2013
		default:
			self.sessionYear = .WWDC2015
		}
		self.sampleCodeArray = aDecoder.decodeObjectForKey("sampleCodeArray") as! [FileInfo]
		
		super.init()

		self.isInfoFetchComplete = aDecoder.decodeBoolForKey("isInfoFetchComplete")
        self.streamingURL = aDecoder.decodeObjectForKey("streamingURL") as? NSURL
		self.hdFile = aDecoder.decodeObjectForKey("hdFile") as? FileInfo
		self.sdFile = aDecoder.decodeObjectForKey("sdFile") as? FileInfo
		self.pdfFile = aDecoder.decodeObjectForKey("pdfFile") as? FileInfo
		self.sessionDescription  = aDecoder.decodeObjectForKey("sessionDescription") as? String
		self.sessionTrack  = aDecoder.decodeObjectForKey("sessionTrack") as? String
		if let boxed = aDecoder.decodeObjectForKey("transcript") as? [TranscriptInfo] {
			self.transcript = boxed
		}
		
		self.fullTranscriptPrettyPrint  = aDecoder.decodeObjectForKey("fullTranscriptPrettyPrint") as? String
		self.transcriptHTMLFormatted  = aDecoder.decodeObjectForKey("transcriptHTMLFormatted") as? String
	}
	
	func encodeWithCoder(aCoder: NSCoder) {
		aCoder.encodeObject(title, forKey: "title")
		aCoder.encodeObject(sessionID, forKey: "sessionID")
		aCoder.encodeObject(sessionYear.description, forKey: "sessionYear")
		aCoder.encodeObject(sampleCodeArray, forKey: "sampleCodeArray")
		aCoder.encodeBool(isInfoFetchComplete, forKey: "isInfoFetchComplete")
        if let streamingFile = self.streamingURL {
            aCoder.encodeObject(streamingFile, forKey: "streamingURL")
        }
		if let hdFile = self.hdFile {
			aCoder.encodeObject(hdFile, forKey: "hdFile")
		}
		if let sdFile = self.sdFile {
			aCoder.encodeObject(sdFile, forKey: "sdFile")
		}
		if let pdfFile = self.pdfFile {
			aCoder.encodeObject(pdfFile, forKey: "pdfFile")
		}
		if let sessionDescription = self.sessionDescription {
			aCoder.encodeObject(sessionDescription, forKey: "sessionDescription")
		}
		if let sessionTrack = self.sessionTrack {
			aCoder.encodeObject(sessionTrack, forKey: "sessionTrack")
		}
		if let transcript = self.transcript {
			aCoder.encodeObject(transcript, forKey: "transcript")
		}
		if let fullTranscriptPrettyPrint = self.fullTranscriptPrettyPrint {
			aCoder.encodeObject(fullTranscriptPrettyPrint, forKey: "fullTranscriptPrettyPrint")
		}
		if let transcriptHTMLFormatted = self.transcriptHTMLFormatted {
			aCoder.encodeObject(transcriptHTMLFormatted, forKey: "transcriptHTMLFormatted")
		}
	}
}
