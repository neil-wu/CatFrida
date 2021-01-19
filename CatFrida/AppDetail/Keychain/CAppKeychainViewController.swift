//
//  CAppKeychainViewController.swift
//  CatFrida
//
//  Created by neilwu on 2021/1/19.
//  Copyright © 2021 nw. All rights reserved.
//

import Cocoa
import HandyJSON

struct CAppKeychainItem: HandyJSON {
    var clazz: String = ""
    var creation: String = ""
    var modification: String = ""
    var description: String = ""
    var comment: String = ""
    var creator: String = ""
    var type: String = ""
    var scriptCode: String = ""
    var alias: String = ""
    var invisible: String = ""
    var negative: String = ""
    var customIcon: String = ""
    var protected: String = ""
    var accessControl: String = ""
    var accessibleAttribute: String = ""
    var entitlementGroup: String = ""
    var generic: String = ""
    var service: String = ""
    var account: String = ""
    var label: String = ""
    var data: String = ""
}

final class CAppKeychainViewController: NSViewController, CAppDetailContentProtocol {

    private weak var appInspector: CAppInspector? = nil;
    
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet var detailTextView: NSTextView!
    
    private var dataList:[CAppKeychainItem] = []
    private var rawDataList:NSArray? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        tableView.delegate = self
        tableView.dataSource = self
        tableView.action = #selector(onClassRowClick)
        
        detailTextView.isEditable = false
        detailTextView.isSelectable = true
        detailTextView.font = Config.codeFont(of: 12)
    }
    
    func setupData(appInspector: CAppInspector?) {
        self.appInspector = appInspector;
        
        appInspector?.call(rpc: .dumpKeyChain, callback: { [weak self] (result:RpcResult<NSArray>) in
            switch(result) {
            case .success(let objs):
                self?.onDataLoaded(objs)
            case .error(let error):
                let str: String = "get KeyChain fail, err \(error.localizedDescription)"
                Log(str)
                self?.toast(str)
            }
        })
    }
    func clearData() {
        self.appInspector = nil;
    }
    
    
    private func onDataLoaded(_ objs: NSArray) {
        rawDataList = objs
        let objs:[CAppKeychainItem] = objs.compactMap { (tmp) -> CAppKeychainItem? in
            if let dict = tmp as? NSDictionary {
                return CAppKeychainItem.deserialize(from: dict)
            }
            return nil
        }
        
        self.dataList = objs
        self.tableView.reloadData()
    }
}

extension CAppKeychainViewController: NSTableViewDataSource, NSTableViewDelegate {
    fileprivate enum CellID: String {
        case ServiceCell
        case SecClassCell
        case ModCell
        case DataCell
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return dataList.count;
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 20;
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        //var image: NSImage?
        var text: String = ""
        var cellIdentifier: String = ""
        
        // 1
        let dataObj = dataList[row];
        
        // 2
        if tableColumn == tableView.tableColumns[0] {
            text = dataObj.service
            cellIdentifier = CellID.ServiceCell.rawValue
        } else if tableColumn == tableView.tableColumns[1] {
            text = dataObj.clazz.removingPrefix("kSecClass")
            cellIdentifier = CellID.SecClassCell.rawValue
        } else if tableColumn == tableView.tableColumns[2] {
            text = dataObj.modification.removingSuffix(" +0000")
            cellIdentifier = CellID.ModCell.rawValue
        } else if tableColumn == tableView.tableColumns[3] {
            text = dataObj.data
            cellIdentifier = CellID.DataCell.rawValue
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
    
    @objc func onClassRowClick() {
        let row = tableView.selectedRow
        if let obj = rawDataList?.object(at: row) {
            detailTextView.string = "\(obj)"
        }
        
        
        
    }
}

