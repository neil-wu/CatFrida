//
//  CAppCookiesViewController.swift
//  CatFrida
//
//  Created by neilwu on 2021/1/19.
//  Copyright © 2021 nw. All rights reserved.
//

import Cocoa
import HandyJSON

struct CAppCookie: HandyJSON {
    var domain: String = ""
    var name: String = ""
    var value: String = ""
    var path: String = ""
    var version: String = ""
    var isSecure: Bool = false
}

final class CAppCookiesViewController: NSViewController, CAppDetailContentProtocol {

    private weak var appInspector: CAppInspector? = nil;
    @IBOutlet weak var tableView: NSTableView!
    private var dataList:[CAppCookie] = []
    
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
        if let str = obj.toJSONString() {
            Util.copyStr(str)
            toast("Copy done")
        }
    }
    
    func setupData(appInspector: CAppInspector?) {
        self.appInspector = appInspector;
        
        appInspector?.call(rpc: .cookies, callback: { [weak self] (result:RpcResult<NSArray>) in
            switch(result) {
            case .success(let objs):
                self?.onDataLoaded(objs)
            case .error(let error):
                Log("get cookie fail, err \(error.localizedDescription)")
            }
        })
    }
    func clearData() {
        self.appInspector = nil;
    }
    
    
    private func onDataLoaded(_ objs: NSArray) {
        
        let objs:[CAppCookie] = objs.compactMap { (tmp) -> CAppCookie? in
            
            if let dict = tmp as? NSDictionary {
                return CAppCookie.deserialize(from: dict)
            }
            return nil
        }
        
        self.dataList = objs
        self.tableView.reloadData()
    }
    
}

extension CAppCookiesViewController: NSTableViewDataSource, NSTableViewDelegate {
    fileprivate enum CellID: String {
        case DomainCell
        case NameCell
        case ValueCell
        case PathCell
        case VersionCell
        case IsSecureCell
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
            text = dataObj.domain
            cellIdentifier = CellID.DomainCell.rawValue
        } else if tableColumn == tableView.tableColumns[1] {
            text = dataObj.name
            cellIdentifier = CellID.NameCell.rawValue
        } else if tableColumn == tableView.tableColumns[2] {
            text = dataObj.value
            cellIdentifier = CellID.ValueCell.rawValue
        } else if tableColumn == tableView.tableColumns[3] {
            text = dataObj.path
            cellIdentifier = CellID.PathCell.rawValue
        } else if tableColumn == tableView.tableColumns[4] {
            text = dataObj.version
            cellIdentifier = CellID.VersionCell.rawValue
        } else if tableColumn == tableView.tableColumns[5] {
            text = "\(dataObj.isSecure)"
            cellIdentifier = CellID.IsSecureCell.rawValue
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

