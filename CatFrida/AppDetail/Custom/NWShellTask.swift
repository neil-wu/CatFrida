//
//  NWShellTask.swift
//  CatFrida
//
//  Created by neilwu on 2020/7/24.
//  Copyright © 2020 nw. All rights reserved.
//

import Foundation
import Cocoa

protocol NWShellTaskProtocol: AnyObject {
    func shellTaskTerminate();
    func shellTaskOutput(_ output: String);
}

final class NWShellTask {
    
    let shellTask: Process
    private var inputPipe: Pipe;
    private var outputPipe: Pipe;
    
    weak var delegate: NWShellTaskProtocol? = nil;
    
    init(launchPath: String, arguments:[String]) {
        shellTask = Process();
        inputPipe = Pipe();
        outputPipe = Pipe();
        
        shellTask.launchPath = launchPath;
        shellTask.arguments = arguments;
        shellTask.terminationHandler = { [weak self] task in
            self?.outputPipe.fileHandleForReading.readabilityHandler = nil;
            self?.delegate?.shellTaskTerminate()
        }
        
        
        outputPipe.fileHandleForReading.readabilityHandler = { [weak self] (handle: FileHandle) in
            let data = handle.availableData;
            if let str: String = String(data: data, encoding: String.Encoding.utf8) {
                self?.delegate?.shellTaskOutput(str);
            }
        }
        shellTask.standardOutput = outputPipe;
        shellTask.standardError = outputPipe;
        shellTask.standardInput = inputPipe;
    }
    
    
    func run() {
        
        shellTask.launch();
        shellTask.waitUntilExit();
    }
    
    func stopTask() {
        shellTask.terminate();
    }
    
    func write(input: String) {
        if let data = input.data(using: String.Encoding.utf8) {
            let fileHandle = self.inputPipe.fileHandleForWriting;
            fileHandle.write(data);
        }
    }
    
    func closeWrite() {
        self.inputPipe.fileHandleForWriting.closeFile()
    }
}
