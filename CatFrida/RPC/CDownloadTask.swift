//
//  CDownloadTask.swift
//  CatFrida
//
//  Created by neilwu on 2020/7/22.
//  Copyright © 2020 nw. All rights reserved.
//

import Foundation

protocol CDownloadTaskProtocol: AnyObject {
    func downloadTaskProgress(_ percent: Float);
    func downloadTaskDone(success: Bool, errstr: String?);
}

final class CDownloadTask {
    
    private(set) var remotePath: String = "";
    private(set) var size: Int64 = 0;
    private(set) var sessionid: String = "";
    
    private(set) var localUrl:URL // save to this url
    
    private var fileHandle: FileHandle? = nil;
    
    public weak var delegate: CDownloadTaskProtocol? = nil;
    
    init(remote: String, size: Int64, session: String, localUrl: URL) {
        self.remotePath = remote;
        self.size = size;
        self.sessionid = session;
        self.localUrl = localUrl;
    }
    
    func openFile() {
        
        do {
            if (FileManager.default.fileExists(atPath: localUrl.path)) {
                try FileManager.default.removeItem(at: localUrl)
            } else {
                FileManager.default.createFile(atPath: localUrl.path, contents: nil, attributes: nil);
            }
            if #available(OSX 10.15, *) {
                try fileHandle?.close()
            } else {
                fileHandle?.closeFile()
            };
            fileHandle = try FileHandle(forWritingTo: localUrl);
        } catch {
            Log("fail to open file at \(self.localUrl), err \(error.localizedDescription)");
            self.delegate?.downloadTaskDone(success: false, errstr: error.localizedDescription);
        }
        
    }
    
    func write(_ newdata: Data?) {
        guard let data = newdata else {
            return;
        }
        fileHandle?.seekToEndOfFile()
        fileHandle?.write(data);
        
        let percent: Double = Double(data.count) / Double(self.size);
        delegate?.downloadTaskProgress(Float(percent))
        
    }
    
    func endWrite() {
        do {
            if #available(OSX 10.15, *) {
                try self.fileHandle?.close()
            } else {
                // Fallback on earlier versions
                fileHandle?.closeFile()
            };
            self.delegate?.downloadTaskDone(success: true, errstr: nil);
        } catch {
            Log("fail to close file \(self.localUrl), err \(error.localizedDescription)");
            self.delegate?.downloadTaskDone(success: false, errstr: error.localizedDescription);
        }
        self.fileHandle = nil;
        self.delegate = nil;
    }
    
    
    
}


