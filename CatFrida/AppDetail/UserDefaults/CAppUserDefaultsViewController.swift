//
//  CAppUserDefaultsViewController.swift
//  CatFrida
//
//  Created by neilwu on 2021/1/19.
//  Copyright © 2021 nw. All rights reserved.
//

import Cocoa
import HandyJSON

struct CAppUserDefaultsObj: HandyJSON {
    var key: String = ""
    var value: Any? = nil
    var valueDesc: String = ""
    
    static func build(key: Any, value: Any) -> CAppUserDefaultsObj? {
        guard let keystr = key as? String else {
            return nil
        }
        var desc: String = ""
        switch value {
        case 0 as Int: desc = "0"
        case 0 as Double: desc = "0.0"
        case let tmp as Int: desc = "\(tmp)"
        case let tmp as Double: desc = "\(tmp)"
        case let tmp as String: desc = tmp
        case let tmp as [Any]: desc = "\(tmp)"
        case let tmp as Dictionary<AnyHashable, Any>: desc = "\(tmp)"
        default:
            break
        }
        let ret = CAppUserDefaultsObj(key: keystr, value: value, valueDesc: desc)
        return ret
    }
}

final class CAppUserDefaultsViewController: NSViewController, CAppDetailContentProtocol {
    
    private weak var appInspector: CAppInspector? = nil;
    @IBOutlet weak var tableView: NSTableView!
    
    private var dataList:[CAppUserDefaultsObj] = []
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        tableView.delegate = self
        tableView.dataSource = self
        
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Copy", action: #selector(onClickTableViewMenu(_:)), keyEquivalent: ""));
        tableView.menu = menu
    }
    
    @objc private func onClickTableViewMenu(_ sender: NSMenuItem) {
        guard let obj = dataList.nwOptionObj(at: tableView.clickedRow) else {
            return
        }
        
        Util.copyStr(obj.valueDesc)
        toast("Copy done")
    }
    
    func setupData(appInspector: CAppInspector?) {
        self.appInspector = appInspector;
        
        appInspector?.call(rpc: .userDefaults, callback: { [weak self] (result:RpcResult<NSDictionary>) in
            switch(result) {
            case .success(let dict):
                self?.onDataLoaded(dict)
            case .error(let error):
                let str: String = "get UserDefaults fail, err \(error.localizedDescription)"
                Log(str)
                self?.toast(str)
            }
        })
    }
    func clearData() {
        self.appInspector = nil;
    }
    
    
    private func onDataLoaded(_ dict: NSDictionary) {
        let sortKeys:[String] = dict.allKeys.compactMap{ $0 as? String}.sorted()
        
        dataList.removeAll()
        
        for key in sortKeys {
            if let value: Any = dict[key] {
                if let obj = CAppUserDefaultsObj.build(key: key, value: value) {
                    dataList.append(obj)
                }
            }
            
        }
        self.tableView.reloadData()
    }
}

extension CAppUserDefaultsViewController: NSTableViewDataSource, NSTableViewDelegate {
    fileprivate enum CellID: String {
        case KeyCell
        case ValueCell
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
        let data = dataList[row];
        
        // 2
        if tableColumn == tableView.tableColumns[0] {
            text = data.key
            cellIdentifier = CellID.KeyCell.rawValue
        } else if tableColumn == tableView.tableColumns[1] {
            cellIdentifier = CellID.ValueCell.rawValue
            text = data.valueDesc
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
