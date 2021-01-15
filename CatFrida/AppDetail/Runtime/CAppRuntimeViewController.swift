//
//  CAppRuntimeViewController.swift
//  CatFrida
//
//  Created by neilwu on 2021/1/7.
//  Copyright © 2021 nw. All rights reserved.
//

import Cocoa

final class CAppRuntimeViewController: NSViewController, CAppDetailContentProtocol, NSSearchFieldDelegate {

    private var appInspector:CAppInspector? = nil
    private var methodLogic: CAppRuntimeClassMethodLogic = CAppRuntimeClassMethodLogic()
    
    @IBOutlet weak var classTableView: NSTableView!
    @IBOutlet weak var methodTableView: NSTableView!
    @IBOutlet weak var methodBox: NSBox!
    @IBOutlet weak var methodProtoLabel: NSTextField!
    @IBOutlet weak var classSearchField: NSSearchField!
    @IBOutlet weak var includeGlobalBtn: NSButton!
    
    private var includeGlobal: Bool {
        return includeGlobalBtn.intValue == 1
    }
    
    private var appClassList:[String] = []
    private var globalClassList:[String] = []
    private var showingClassList:[String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        classTableView.delegate = self
        classTableView.dataSource = self
        classTableView.action = #selector(onClassRowClick)
        
        methodLogic.bindTable(methodTableView)
        
        classSearchField.delegate = self
        classSearchField.sendsWholeSearchString = true
        
        methodBox.isHidden = true
    }
    
    func setupData(appInspector: CAppInspector?) {
        self.appInspector = appInspector;
        loadRuntime(isGlobal: false)
    }
    
    func clearData() {
        self.appInspector = nil;
    }
    
    
    @objc func onClassRowClick() {
        methodBox.isHidden = false
        let row = classTableView.selectedRow
        let name = showingClassList[row];
        loadMethod(for: name)
    }
    
    func loadRuntime(isGlobal: Bool) {
        let rpc = isGlobal ? CAppRpc.classes : CAppRpc.ownClasses
        appInspector?.call(rpc: rpc, callback: { [weak self] (result: RpcResult<NSArray>) in
            switch(result) {
            case .success(let classList):
                Log("classList num \(classList.count)")
                self?.onLoaded(classList, isGlobal: isGlobal)
            case .error(let error):
                Log("err \(error.localizedDescription)");
            }
        })
    }
    
    
    func onLoaded(_ classList: NSArray, isGlobal: Bool) {
        if (isGlobal) {
            globalClassList = classList as? [String] ?? []
            showingClassList = globalClassList
        } else {
            appClassList = classList as? [String] ?? []
            showingClassList = appClassList
        }
        classTableView.reloadData()
    }
    
    
    private func loadMethod(for className: String) {
        
        appInspector?.call(rpc: .inspect(className: className), callback: { [weak self] (result: RpcResult<NSDictionary>) in
            switch(result) {
            case .success(let methodInfo):
                Log("method \(methodInfo)")
                self?.methodLogic.updateInfo(methodInfo, type: className)
                self?.methodBox.title = className
                self?.methodProtoLabel.stringValue = self?.methodLogic.protoDesc ?? "no proto"
                
                self?.methodTableView.reloadData()
            case .error(let error):
                Log("err \(error.localizedDescription)");
            }
        })
    }
    
    
    @IBAction func onSearchField(_ sender: NSSearchField) {
        Log("search sender.stringValue")
        
        let str: String = sender.stringValue
        guard !str.isEmpty else {
            return
        }
        let srcList = includeGlobal ? globalClassList : appClassList
        showingClassList = srcList.filter{ $0.contains(str) }
        self.classTableView.reloadData()
        if showingClassList.isEmpty {
            self.toast("Empty result")
        }
    }
    
    func searchFieldDidEndSearching(_ sender: NSSearchField) {
        let srcList = includeGlobal ? globalClassList : appClassList
        showingClassList = srcList
        self.classTableView.reloadData()
    }
    @IBAction func onCopyMethodBtn(_ sender: Any) {
        Util.copyStr(methodLogic.makeDumpDesc())
        self.toast("Success")
    }
}

extension CAppRuntimeViewController: NSTableViewDataSource, NSTableViewDelegate {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return showingClassList.count;
    }
    
    fileprivate enum CellIdentifiers {
        static let NameCell = "NameCell"
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 20;
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        //var image: NSImage?
        var text: String = ""
        var cellIdentifier: String = ""
        
        // 1
        let name = showingClassList[row];
        
        // 2
        if tableColumn == tableView.tableColumns[0] {
            text = name
            cellIdentifier = CellIdentifiers.NameCell
        }
        
        // 3
        let identifier = NSUserInterfaceItemIdentifier(cellIdentifier);
        if let cell = tableView.makeView(withIdentifier: identifier, owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = text
            cell.toolTip = text;
            return cell
        }
        
        return nil;
    }
    
    
}
