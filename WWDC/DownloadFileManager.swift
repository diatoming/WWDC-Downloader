//
//  DownloadFileManager.swift
//  WWDC
//
//  Created by David Roberts on 17/06/2015.
//  Copyright © 2015 Dave Roberts. All rights reserved.
//

import Foundation

let logFileManager = false

typealias ProgressHandler = ((progress: Float) -> Void)
typealias SimpleCompletionHandler = ((success: Bool) -> Void)

@objc class DownloadFileManager : NSObject, NSURLSessionDownloadDelegate {
	
	// MARK: - Instance Variables	
	private var backgroundHandlersForFiles: [FileInfo : CallbackWrapper] = [:]
    private var backgroundRequestsForFiles: [NSURLSessionDownloadTask : FileInfo] = [:]
    
    private var sessionManager : NSURLSession?
    
  	// MARK: - Singleton Status
	class var sharedManager: DownloadFileManager {
		struct Singleton {
			static let instance = DownloadFileManager()
		}
		return Singleton.instance
	}
	
	// MARK: - Object Lifecycle Methods
	// Singleton so prevent init outside of class by marking private
	private override init() {
        
        super.init()
        
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        config.HTTPMaximumConnectionsPerHost = 3
        sessionManager = NSURLSession(configuration: config, delegate: self, delegateQueue: nil)
	}
	
    // MARK: - Download File Transfer

    func downloadFile(file: FileInfo, progressWrapper: ProgressWrapper?, completionWrapper:SimpleCompletionWrapper?) {

        // Check if it exists locally
		if fileExistsLocallyForFile(file) {

            if let url = file.localFileURL {
                do {
                    if let path = url.path {
                        let fileAttributes = try NSFileManager.defaultManager().attributesOfItemAtPath(path)
                        if let size = fileAttributes["NSFileSize"] as? Int {
                            if size == file.fileSize {
                                print("Already Downloaded! - \(file.displayName!)")
                                
                                if let completionWrapper = completionWrapper {
                                    completionWrapper.execute(true)
                                }
                                return
                            }
                        }
                    }
                }
                catch {
                    print(error)
                    return
                }
            }
        }
							
        //  Handle Callbacks
        if let backgroundDownloadHandler = backgroundHandlersForFiles[file] {				// there is a background download available
            backgroundDownloadHandler.addProgressWrapper(progressWrapper)
            backgroundDownloadHandler.addCompletionWrapper(completionWrapper)
        }
        else {																						// no download at all - create callbacks and start
            let callbackWrapper = CallbackWrapper(file: file)
            callbackWrapper.addProgressWrapper(progressWrapper)
            callbackWrapper.addCompletionWrapper(completionWrapper)
            backgroundHandlersForFiles[file] = callbackWrapper
            
            startDownload(file, callbacks: callbackWrapper)
        }
    }
    
    private func startDownload(file: FileInfo, callbacks:CallbackWrapper?) {
        
        if logFileManager { print("Queue Download of \(file.displayName!)") }
        
        if let url = file.remoteFileURL {
            let downloadTask = sessionManager?.downloadTaskWithRequest(NSURLRequest(URL: url))
            
            if let task = downloadTask {
                backgroundRequestsForFiles[task] = file
                task.resume()
            }
        }
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64)  {
        
        var progress = Float(totalBytesWritten)/Float(totalBytesExpectedToWrite)
        if progress > 1 {
            progress = 1;
        }
        
        if let fileInfo = backgroundRequestsForFiles[downloadTask] {
            if let callback = backgroundHandlersForFiles[fileInfo] {
                callback.notifyProgress(progress, file: fileInfo)
            }
        }
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        
        if let fileInfo = backgroundRequestsForFiles[downloadTask] {
            saveFile(url: location, forFile: fileInfo)
        }
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        
        if  let downloadTask = task as? NSURLSessionDownloadTask {
            if let fileInfo = backgroundRequestsForFiles[downloadTask] {
                if let callback = backgroundHandlersForFiles[fileInfo] {
                    
                    if let error = error {
                        callback.notifyCompletion(false, file: fileInfo, error: error)
                    }
                    else {
                        callback.notifyCompletion(true, file: fileInfo, error: nil)
                    }
                    
                    self.backgroundHandlersForFiles[fileInfo] = nil
                    self.backgroundRequestsForFiles[downloadTask] = nil
                }
            }
        }
    }


	// MARK: - File Methods
	
	func fileExistsLocallyForFile(file: FileInfo) -> Bool {
        if let localFileURL = file.localFileURL {
            if let localFileURLString = localFileURL.path {
                return NSFileManager.defaultManager().fileExistsAtPath(localFileURLString)
            }
        }
        return false
	}
    
    func saveFile(url oldURL: NSURL, forFile file: FileInfo) {
        
        if fileExistsLocallyForFile(file) == false {
            // Copy the file over to the correct location
            if let localFileURL = file.localFileURL {
                do {
                    try NSFileManager.defaultManager().moveItemAtURL(oldURL, toURL: localFileURL)
                }
                catch {
                    print("File move/save error - \(error)")
                }
            }
        }
    }
	
	
	// MARK: - CallbackWrapper
	
	private class CallbackWrapper {
		
		// MARK: Instance Variables
		
		let file: FileInfo
		var progressWrappers: [ProgressWrapper] = []
		var completionWrappers: [SimpleCompletionWrapper] = []
		var currentProgress: Float = 0
		
		// MARK: - Object Lifecycle Methods
		
		init(file: FileInfo) {
			self.file = file
		}
		
		// MARK: - Helper Methods
		
		func addProgressWrapper(wrapper: ProgressWrapper?) {
			if let wrapper = wrapper {
				progressWrappers.append(wrapper)
			}
		}

		func addCompletionWrapper(wrapper: SimpleCompletionWrapper?) {
			if let wrapper = wrapper {
				completionWrappers.append(wrapper)
			}
		}
		
        func notifyProgress(progress: Float, file : FileInfo?) {
            if let file = file {
                if logFileManager { print(" file DOWNLOAD progress: \(file.displayName!) - \(progress)") }
            }
           
			var wrappersToRemove: [ProgressWrapper] = []
			for wrapper in progressWrappers {
				if wrapper.execute(progress) == false {
					wrappersToRemove.append(wrapper)
				}
			}
			// Remove any now invalid wrappers
			for invalidWrapper in wrappersToRemove {
				if let index = progressWrappers.indexOf(invalidWrapper) {
					progressWrappers.removeAtIndex(index)
				}
			}
		}
		
        func notifyCompletion(success: Bool, file: FileInfo?, error: NSError?) {
            
            if (success) {
                 if let file = file {
                    if logFileManager { print(" file transfer complete! \(file.displayName!)") }
                }
            }
            else {
                if let file = file {
                    if logFileManager { print(" file transfer error! - \(file.displayName!) - \(error)") }
                }
            }
            
			var wrappersToRemove: [SimpleCompletionWrapper] = []
			for wrapper in completionWrappers {
				if wrapper.execute(success) == false {
					wrappersToRemove.append(wrapper)
				}
			}
			// Remove any now invalid wrappers
			for invalidWrapper in wrappersToRemove {
				if let index = completionWrappers.indexOf(invalidWrapper) {
					completionWrappers.removeAtIndex(index)
				}
			}
		}
	}
	
}