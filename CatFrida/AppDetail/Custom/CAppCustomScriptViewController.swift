//
//  CAppCustomScriptViewController.swift
//  CatFrida
//
//  Created by neilwu on 2020/7/24.
//  Copyright © 2020 nw. All rights reserved.
//

import Cocoa

final class CAppCustomScriptViewController: NSViewController, CAppDetailContentProtocol, NSTextFieldDelegate, NWShellTaskProtocol {

    @IBOutlet weak var scriptTextField: NSTextField!
    @IBOutlet weak var cmdTextField: NSTextField!
    @IBOutlet weak var logTextView: NSTextView!
    @IBOutlet weak var fullCmdLabel: NSTextField!
    @IBOutlet weak var inputCmdTextField: NSTextField!
    @IBOutlet weak var runBtn: NSButton!
    
    private var isRunning: Bool = false {
        didSet {
            DispatchQueue.main.async {
                self.runBtn.title = self.isRunning ? "Stop" : "Run";
            }
        }
    }
    private var shellTask: NWShellTask? = nil;
    
    private var fullCmdStr: String = "" {
        didSet {
            self.fullCmdLabel.stringValue = fullCmdStr;
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        logTextView.font = Config.codeFont;
        
        self.scriptTextField.stringValue = Setting.shared.customScriptPath;
        let cmd = Setting.shared.customScriptCmd;
        if (cmd.isEmpty) {
            self.cmdTextField.stringValue = "/usr/local/bin/frida -U -F";
        } else {
            self.cmdTextField.stringValue = cmd;
        }
        
        self.scriptTextField.delegate = self
        self.cmdTextField.delegate = self
        
        self.updateFullCmd();
    }
    
    func setupData(appInspector: CAppInspector?) {
        //self.appInspector = appInspector;
    }
    func clearData() {
        //self.appInspector = nil;
    }
    
    func controlTextDidChange(_ obj: Notification) {
        /*
        guard let textFiled = obj.object as? NSTextField else {
            return;
        }*/
        self.updateFullCmd();
    }
    
    @IBAction func onChooseBtn(_ sender: Any) {
        guard let window: NSWindow = NSApplication.shared.keyWindow else {
            return;
        }
        
        let dialog = NSOpenPanel();
        let fileTypes = ["js"];
        dialog.canChooseFiles = true;
        dialog.allowedFileTypes = fileTypes;
        dialog.allowsMultipleSelection = false;
        
        dialog.beginSheetModal(for: window) { [weak self] (rsp:NSApplication.ModalResponse) in
            if (rsp == .OK) {
                if let url = dialog.url {
                    Log("user select \(url.absoluteString)");
                    DispatchQueue.main.async { [weak self] in
                        let str = url.absoluteString.removingPrefix("file://")
                        self?.scriptTextField.stringValue = str;
                        Setting.shared.customScriptPath = str;
                        self?.updateFullCmd();
                    }
                }
            }
        }
    }
    
    func updateFullCmd() {
        self.fullCmdStr = self.cmdTextField.stringValue + " -l '\(self.scriptTextField.stringValue)' ";
    }
    
    @IBAction func onSendInput(_ sender: Any) {
        self.shellTask?.write(input: self.inputCmdTextField.stringValue + "\n");
        self.inputCmdTextField.stringValue = "";
    }
    private var fridaTask: Process? = nil;
    private var outputPipe: Pipe? = nil;
    
    @IBAction func onRunBtn(_ sender: Any) {
        // frida -D '00008020-00014CA91E83002E' -F -l ./frida-agent/_agent.js
        if (self.isRunning) {
            self.isRunning = false;
            self.shellTask?.stopTask();
            return;
        }
        
        Setting.shared.customScriptPath = self.scriptTextField.stringValue;
        Setting.shared.customScriptCmd = self.cmdTextField.stringValue; //save it
        
        self.isRunning = true;
        
        let taskQueue = DispatchQueue.global(qos: DispatchQoS.QoSClass.background)
        taskQueue.async { [weak self] in
            self?.runTask();
        }
    }
    
    func runTask() {
        shellTask?.delegate = nil;
        
        shellTask = NWShellTask(launchPath: "/bin/bash", arguments: ["-c", self.fullCmdStr]);
        
        shellTask?.delegate = self;
        shellTask?.run();
    }
    
    func shellTaskTerminate() {
        Log("")
        self.isRunning = false;
    }
    func shellTaskOutput(_ output: String) {
        DispatchQueue.main.async(execute: { [weak self] in
            let outputString: String = output;
            let previousOutput = self?.logTextView.string ?? ""
            let nextOutput = previousOutput + "\n" + outputString
            self?.logTextView.string = nextOutput
            
            let range = NSRange(location:nextOutput.count,length:0)
            self?.logTextView.scrollRangeToVisible(range)
        })
    }
    
    
}


