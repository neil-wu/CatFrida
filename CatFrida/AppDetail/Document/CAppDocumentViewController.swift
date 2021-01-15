//
//  CAppDocumentViewController.swift
//  CatFrida
//
//  Created by neilwu on 2020/7/21.
//  Copyright © 2020 nw. All rights reserved.
//

import Cocoa
import HandyJSON

/*
{
    creation = "2020-07-07 09:13:12 +0000";
    group = mobile;
    modification = "2020-07-07 09:13:12 +0000";
    owner = mobile;
    permission = 493;
    size = 64;
    type = NSFileTypeDirectory;
};
*/
struct CAppDocFileAttr: HandyJSON {
    var creation: String = ""; // "2020-07-07 09:13:12 +0000";
    var modification: String = ""; // "2020-07-07 09:13:12 +0000";
    var group: String = ""; // mobile
    var owner: String = ""; // mobile
    var permission: Int = 0; //493
    var size: Int64 = 0;
    //var type // NSFileTypeDirectory
}
enum CappDocFileType: String, HandyJSONEnum {
    case file = "file"
    case directory = "directory"
}

struct CAppDocFile: HandyJSON {
    var name: String = ""; // file name
    var path: String = ""; //full file path
    var type: CappDocFileType = CappDocFileType.file;
    var attribute: CAppDocFileAttr = CAppDocFileAttr();
}

struct CAppDocResult: HandyJSON {
    var cwd: String = ""; //path
    var list: [CAppDocFile] = []; // files
}

final class CAppDocumentViewController: NSViewController, CAppDetailContentProtocol, NSTextFieldDelegate {
    enum Menus: String {
        case Download = "Download"
        case openAsTextFile = "Open As Text File"
    }
    
    private var isLoading: Bool = false {
        didSet {
            DispatchQueue.main.async {
                self.loadingIndicator.isHidden = !self.isLoading;
                if (self.isLoading) {
                    self.loadingIndicator.startAnimation(nil)
                } else {
                    self.loadingIndicator.stopAnimation(nil)
                }
            }
        }
    }
    
    private var dataPath: String = "";
    private var bundlePath: String = "";
    
    private var cwd: String = "";
    private var filesList:[CAppDocFile] = [];
    
    private weak var appInspector: CAppInspector? = nil;
    
    @IBOutlet weak var segmentControl: NSSegmentedControl!
    @IBOutlet weak var pathTextField: NSTextField!
    @IBOutlet weak var pathBtn: NSButton!
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var loadingIndicator: NSProgressIndicator!
    //@IBOutlet weak var tipLabel: NSTextField!
    
    deinit {
        print("~~~ CAppDocumentViewController")
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        self.tableView.target = self;
        self.tableView.doubleAction = #selector(onDoubleClickTable);
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Download", action: #selector(onClickTableViewMenu(_:)), keyEquivalent: ""));
        tableView.menu = menu
                
        pathTextField.delegate = self
    }
    
    @objc func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if (commandSelector == #selector(NSResponder.insertNewline(_:))) {
            // ENTER key
            onPathBtn(nil)
            return true
        }
        return false
    }
    
    
    @objc private func onClickTableViewMenu(_ sender: NSMenuItem) {
        guard tableView.clickedRow >= 0, !self.isLoading else {
            return
        }
        let item = filesList[tableView.clickedRow];
        if (item.type == .directory) {
            let err = "Doesn't support to download directory!"
            Log(err)
            self.toast(err)
            return;
        }
        //print("item", item)
        guard let window: NSWindow = NSApplication.shared.keyWindow else {
            return;
        }
        let path: String = item.path;
        let panel = NSSavePanel();
        panel.nameFieldStringValue = item.name;
        panel.beginSheetModal(for: window) { [weak self] (rsp:NSApplication.ModalResponse) in
            if (rsp == .OK) {
                if let url = panel.url {
                    Log("user select \(url)");
                    self?.appInspector?.downloadFile(path: path, to: url) { [weak self] session in
                        self?.addDownloadTaskListener(session);
                    }
                }
            }
        }
    }
    private func addDownloadTaskListener(_ session: String) {
        guard let task = self.appInspector?.getDownloadTask(of: session) else {
            return;
        }
        task.delegate = self;
        
        self.isLoading = true;
        /*DispatchQueue.main.async {
            //self.tipLabel.stringValue = "downloading..."
        }*/
    }
    
    func setupData(appInspector: CAppInspector?) {
        self.appInspector = appInspector;

        segmentControl.selectedSegment = 1
        onSegmentChange(segmentControl)
    }
    func clearData() {
        self.appInspector = nil;
    }
    
    private func fetchBy(path: String) {
        
        if (self.isLoading) {
            Log("wait loading")
            return;
        }
        
        self.isLoading = true;
        
        appInspector?.call(rpc: .ls(path: path), callback: { [weak self] (result: RpcResult<NSDictionary>) in
            self?.isLoading = false;
            
            switch(result) {
            case .success(let obj):
                self?.onFiles(obj)
            case .error(let error):
                let err: String = "fetch fail, err \(error.localizedDescription)"
                Log(err)
                DispatchQueue.main.async {
                    self?.toast(err)
                }
            }
        })
    }
    private func onFiles(_ obj: NSDictionary) {
        guard let docResult = CAppDocResult.deserialize(from: obj) else {
            return;
        }
        Log("success, cnt \(docResult.list.count)")
        self.cwd = docResult.cwd;
        self.filesList = docResult.list;
        
        //self.pathControl.url = URL(fileURLWithPath: cwd)
        pathTextField.stringValue = cwd
        self.reloadTable();
    }
    
    @IBAction func onSegmentChange(_ sender: NSSegmentedControl) {
        if (sender.selectedSegment == 0) {
            // payload
            if (self.bundlePath.isEmpty) {
                self.rpcCallForGetPath(.appBundlePath);
            } else {
                self.fetchBy(path: self.bundlePath)
            }
        } else {
            // data
            if (self.dataPath.isEmpty) {
                self.rpcCallForGetPath(.appDataPath);
            } else {
                self.fetchBy(path: self.dataPath)
            }
        }
    }
    
    private func rpcCallForGetPath(_ rpc: CAppRpc) {
        self.isLoading = true;
        
        appInspector?.call(rpc: rpc, callback: { [weak self] (result:RpcResult<NSString>) in
            self?.isLoading = false;
            switch(result) {
            case .success(let str):
                let path: String = str as String;
                
                if case .appDataPath = rpc {
                    self?.dataPath = path;
                } else if case .appBundlePath = rpc {
                    self?.bundlePath = path;
                }
                
                self?.fetchBy(path: path);
            case .error(let error):
                Log("err \(error.localizedDescription)")
            }
        })
    }
    
    
    @IBAction func onPathBtn(_ sender: Any?) {
        let fixPath: String = pathTextField.stringValue
        
        if (fixPath == self.cwd) {
            return;
        }
        self.fetchBy(path: fixPath)
    }
    
    @objc func onDoublePath(_ sender: AnyObject) {
        //print(sender, self.pathControl.clickedPathItem)
        /*
        guard let tapItem: NSPathControlItem = self.pathControl.clickedPathItem else {
            return;
        }
        guard let path:String = tapItem.url?.absoluteString else {
            return;
        }
        let fixPath: String = path.removingPrefix("file://")
        if (fixPath == self.cwd) {
            return;
        }
        self.fetchBy(path: fixPath)*/
    }
}

extension CAppDocumentViewController: CDownloadTaskProtocol {
    func downloadTaskProgress(_ percent: Float) {
        let val:Int = Int(percent * 100);
        /*DispatchQueue.main.async {
            self.tipLabel.stringValue = "\(val)%"
        }*/
        print("progress \(val)%")
    }
    func downloadTaskDone(success: Bool, errstr: String?) {
        DispatchQueue.main.async {
            let tip: String = success ? "Download Success" : (errstr ?? "");
            self.isLoading = false;
            //self.tipLabel.stringValue = tip;
            self.toast(tip)
        }
        
    }
}

extension CAppDocumentViewController: NSTableViewDelegate, NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return filesList.count;
    }
    
    fileprivate enum CellIdentifiers {
        static let NameCell = "NameCell"
        static let FileSizeCell = "FileSizeCell"
        static let ModifyDateCell = "ModifyDateCell"
        
    }
    
    func reloadTable() {
        //self.numLabel.stringValue = "total: \(self.showingModules.count)"
        tableView.reloadData()
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 20;
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        var image: NSImage?
        var text: String = ""
        var cellIdentifier: String = ""
        // 1
        let docFile:CAppDocFile = filesList[row];
        // 2
        if tableColumn == tableView.tableColumns[0] {
            text = docFile.name;
            cellIdentifier = CellIdentifiers.NameCell;
            if (docFile.type == .directory) {
                image = NSImage(named: "NSFolder")
            } else {
                //image = NSImage(named: "NSMultipleDocuments")
                image = NSImage(named: "ic_file")
            }
        } else if tableColumn == tableView.tableColumns[1] {
            text = docFile.attribute.modification;
            cellIdentifier = CellIdentifiers.ModifyDateCell
        } else if tableColumn == tableView.tableColumns[2] {
            text = Util.readbleByteSize(docFile.attribute.size)
            cellIdentifier = CellIdentifiers.FileSizeCell;
        }
        
        // 3
        let identifier = NSUserInterfaceItemIdentifier(cellIdentifier);
        if let cell = tableView.makeView(withIdentifier: identifier, owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = text
            cell.imageView?.image = image;
            cell.toolTip = text;
            return cell
        }
        
        return nil;
    }
    func tableView(_ tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
        
    }
    
    @objc func onDoubleClickTable() {
        let selectedRow = self.tableView.selectedRow;
        Log("selectedRow \(selectedRow)");
        guard let docFile = self.filesList.nwOptionObj(at: selectedRow) else {
            return;
        }
        if (docFile.type == .file) {
            return;
        }
        let path = docFile.path;
        self.fetchBy(path: path);
    }
}


