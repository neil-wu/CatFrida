//
//  CAppModuleViewController.swift
//  CatFrida
//
//  Created by neilwu on 2020/7/21.
//  Copyright © 2020 nw. All rights reserved.
//

import Cocoa
import HandyJSON

struct CAppModule: HandyJSON {
    var base:String = ""; // 0x1111
    var name:String = "";
    var path:String = "";
    var size:Int64 = 0;
}

final class CAppModuleViewController: NSViewController, CAppDetailContentProtocol, NSTableViewDataSource, NSTableViewDelegate {

    @IBOutlet weak var showSysLibBtn: NSButton!
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var tipLabel: NSTextField!
    
    private var allModules:[CAppModule] = [];
    private var showingModules:[CAppModule] = [];
    
    private var isLoading: Bool = false;
    
    private var appInspector: CAppInspector? = nil;
    
    deinit {
        print("~~~ CAppModuleViewController")
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        self.view.layer?.backgroundColor = NSColor.gridColor.cgColor;
        
        
        self.tableView.target = self;
        self.tableView.doubleAction = #selector(onDoubleClickTable);
        
        let menu = NSMenu()
        let dumpItem = NSMenuItem(title: "dumpdecrypted", action: #selector(onClickTableViewMenu(_:)), keyEquivalent: "")
        dumpItem.tag = 1
        let copyItem = NSMenuItem(title: "copy path", action: #selector(onClickTableViewMenu(_:)), keyEquivalent: "")
        copyItem.tag = 2
        let symbolItem = NSMenuItem(title: "symbols", action: #selector(onClickTableViewMenu(_:)), keyEquivalent: "")
        symbolItem.tag = 3
        
        menu.addItem(dumpItem);
        menu.addItem(copyItem);
        menu.addItem(symbolItem);
        tableView.menu = menu
    }
    
    @objc private func onClickTableViewMenu(_ sender: NSMenuItem) {
        guard tableView.clickedRow >= 0, !self.isLoading else {
            return;
        }
        
        let item = showingModules[tableView.clickedRow];
        if (sender.tag == 1) {
            guard let window: NSWindow = NSApplication.shared.keyWindow else {
                return;
            }
            let moduleName: String = item.name;
            let panel = NSSavePanel();
            panel.nameFieldStringValue = moduleName + ".decrypted";
            panel.beginSheetModal(for: window) { [weak self] (rsp:NSApplication.ModalResponse) in
                if (rsp == .OK) {
                    if let url = panel.url {
                        Log("user select \(url)");
                        self?.dumpdecrypted(module: moduleName, to: url);
                    }
                }
            }
        } else if (sender.tag == 2) {
            Util.copyStr(item.path)
            self.toast("Success")
        } else if (sender.tag == 3) {
            let symbolVC = CModuleSymbolViewController()
            symbolVC.setupData(appInspector: self.appInspector, module: item.name)
            self.presentAsSheet(symbolVC)
        }
        
    }
    
    func showTips(_ str: String) {
        DispatchQueue.main.async { [weak self] in
            self?.tipLabel.stringValue = str
        }
    }
    
    func dumpdecrypted(module: String, to localUrl: URL) {
        self.isLoading = true;
        self.showTips("decrypt...");
        
        appInspector?.call(rpc: .dumpdecrypted(module: module), callback: { [weak self] (result:RpcResult<NSString>) in
            self?.isLoading = false;
            switch(result) {
            case .success(let path):
                let remotePath:String = path as String
                if (remotePath.hasPrefix("fail:")) {
                    self?.showTips(remotePath);
                    return;
                }
                Log("dumpdecrypted success, remotePath \(remotePath)")
                DispatchQueue.main.async { [weak self] in
                    self?.downladFile(from: remotePath, to: localUrl);
                }
            case .error(let error):
                Log("err \(error.localizedDescription)")
                //self?.showTips("decrypt fail, \(error.localizedDescription)");
                self?.toast("decrypt fail, \(error.localizedDescription)")
            }
        })
    }
    func downladFile(from: String, to localUrl: URL) {
        self.appInspector?.downloadFile(path: from, to: localUrl) { [weak self] session in
            self?.addDownloadTaskListener(session);
        }
    }
    private func addDownloadTaskListener(_ session: String) {
        guard let task = self.appInspector?.getDownloadTask(of: session) else {
            return;
        }
        task.delegate = self;
        self.isLoading = true;
        self.showTips("downloading...")
    }
    
    func setupData(appInspector: CAppInspector?) {
        
        self.appInspector = appInspector;
        
        appInspector?.call(rpc: .modules, callback: { [weak self] (result: RpcResult<NSArray>) in
            switch(result) {
            case .success(let modules):
                Log("modules num \(modules.count)")
                self?.showTips("Load success, \(modules.count) modules")
                self?.onModules(modules)
            case .error(let error):
                Log("err \(error.localizedDescription)");
                self?.showTips(error.localizedDescription)
            }
        })
    }
    func clearData() {
        self.appInspector = nil;
    }
    
    func onModules(_ modules: NSArray) {
        self.allModules = modules.map({ (obj: Any) -> CAppModule? in
            if let module = CAppModule.deserialize(from: obj as? NSDictionary) {
                return module
            }
            return nil;
        }).filter{ $0 != nil}.map{$0!};
        
        self.showingModules = allModules.filter({ (module:CAppModule) -> Bool in
            return module.path.contains(".app")
        });
        Log("showing modules \(self.showingModules.count)")
        self.reloadTable();
    }
    
    @IBAction func onShowSysLib(_ sender: NSButton) {
        let isChecked:Bool = sender.integerValue == 1;
        if (isChecked) {
            self.showingModules = self.allModules
        } else {
            self.showingModules = allModules.filter({ (module:CAppModule) -> Bool in
                return module.path.contains(".app")
            });
        }
        self.reloadTable();
    }
    
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return showingModules.count;
    }
    
    fileprivate enum CellIdentifiers {
        static let AddressBaseCell = "AddressBaseCell"
        static let NameCell = "NameCell"
        static let SizeCell = "SizeCell"
        static let PathCell = "PathCell"
        
    }
    
    func reloadTable() {
        /*
        self.showingApps = self.showingApps.sorted(by: { (a:ApplicationDetails, b:ApplicationDetails) -> Bool in
            switch(self.sortOrder) {
            case .name:
                if (self.sortAscending) {
                    return a.name < b.name;
                } else {
                    return a.name > b.name;
                }
            case .bundleid:
                if (self.sortAscending) {
                    return a.identifier < b.identifier;
                } else {
                    return a.identifier > b.identifier;
                }
            case .pid:
                let pa:UInt32 = a.pid ?? 0;
                let pb:UInt32 = b.pid ?? 0;
                return (self.sortAscending) ? pa < pb : pa > pb;
            }
            
        })*/
        self.tipLabel.stringValue = "total: \(self.showingModules.count)"
        tableView.reloadData()
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 20;
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        //var image: NSImage?
        var text: String = ""
        var cellIdentifier: String = ""
        
        // 1
        let module:CAppModule = showingModules[row];
        
        // 2
        if tableColumn == tableView.tableColumns[0] {
            text = module.base//String(format: "0x%x", module.base);
            cellIdentifier = CellIdentifiers.AddressBaseCell
        } else if tableColumn == tableView.tableColumns[1] {
            text = module.name;
            cellIdentifier = CellIdentifiers.NameCell
        } else if tableColumn == tableView.tableColumns[2] {
            text = Util.readbleByteSize(module.size);
            cellIdentifier = CellIdentifiers.SizeCell
        } else if tableColumn == tableView.tableColumns[3] {
            text = module.path
            cellIdentifier = CellIdentifiers.PathCell
        }
        
        // 3
        let identifier = NSUserInterfaceItemIdentifier(cellIdentifier);
        if let cell = tableView.makeView(withIdentifier: identifier, owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = text
            //cell.imageView?.image = image
            cell.toolTip = text;
            return cell
        }
        
        return nil;
    }
    func tableView(_ tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
        // 1
        /* guard let sortDescriptor = tableView.sortDescriptors.first else {
            return
        }
        if let order = AppOrder(rawValue: sortDescriptor.key ?? "") {
            self.sortOrder = order;
            self.sortAscending = sortDescriptor.ascending;
            self.reloadAppList();
        }*/
        
    }
    
    
    
    
    @objc func onDoubleClickTable() {
        /*
        let selectedRow = self.tableView.selectedRow;
        Log("selectedRow \(selectedRow)");
        guard let app = self.showingApps.nwOptionObj(at: selectedRow) else {
            return;
        }
        
        showAlert(question: "select", text: "\(selectedRow)")
        self.openApp(app);
        
        */
    }
}

extension CAppModuleViewController: CDownloadTaskProtocol {
    func downloadTaskProgress(_ percent: Float) {
        let val:Int = Int(percent * 100);
        
        self.showTips("downloading... \(val)%");
    }
    func downloadTaskDone(success: Bool, errstr: String?) {
        self.isLoading = false;
        let tip: String = success ? "Download Success" : (errstr ?? "");
        self.showTips(tip);
    }
}



