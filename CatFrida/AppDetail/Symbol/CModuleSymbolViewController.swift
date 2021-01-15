//
//  CModuleSymbolViewController.swift
//  CatFrida
//
//  Created by neilwu on 2021/1/7.
//  Copyright © 2021 nw. All rights reserved.
//

import Cocoa
import HandyJSON


struct CModuleSymbol: HandyJSON {
    var type: String = ""
    var name: String = ""
    var address: String = ""
}

final class CModuleSymbolViewController: NSViewController {

    enum SymbolType: String {
        case exports
        case imports
        
        func toRpc(module: String) -> CAppRpc {
            switch self {
            case .exports: return CAppRpc.exports(module: module)
            case .imports: return CAppRpc.imports(module: module)
            
            }
        }
    }
    
    @IBOutlet weak var typeSegment: NSSegmentedControl!
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var numLabel: NSTextField!
    
    private var exportSymbols:[CModuleSymbol] = []
    private var importSymbols:[CModuleSymbol] = []
    
    private var appInspector:CAppInspector? = nil
    private var module: String = ""
    
    private var showingType: SymbolType {
        if (typeSegment.intValue == 0) {
            return .exports
        }
        return .imports
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    
    
    @IBAction func onCloseBtn(_ sender: Any) {
        if let from = self.presentingViewController {
            from.dismiss(self)
            
            self.appInspector = nil
        }
    }
    
    func setupData(appInspector: CAppInspector?, module: String) {
        
        self.appInspector = appInspector;
        self.module = module
        
        loadSymbols(type: .exports)
    }
    func clearData() {
        self.appInspector = nil;
    }
    
    private func hasCachedData(of type: SymbolType) -> Bool {
        switch type {
        case .exports: return !exportSymbols.isEmpty
        case .imports: return !importSymbols.isEmpty
        }
    }
    
    func loadSymbols(type: SymbolType) {
        if hasCachedData(of: type) {
            reloadTable()
            return
        }
        
        appInspector?.call(rpc: type.toRpc(module: module), callback: { [weak self] (result:RpcResult<NSArray>) in
            switch(result) {
            case .success(let symbols):
                Log("symbols num \(symbols.count)")
                self?.onSymbolsLoaded(symbols, type: type)
            case .error(let error):
                Log("err \(error.localizedDescription)");
            //self?.showTips(error.localizedDescription)
            }
        })
    }
    
    private func onSymbolsLoaded(_ symbols: NSArray, type: SymbolType) {
        
        var addressSet:Set<String> = []
        let objs:[CModuleSymbol] = symbols.compactMap { (tmp) -> CModuleSymbol? in
            
            if let dict = tmp as? NSDictionary {
                if let addr: String = dict["address"] as? String {
                    let result = addressSet.insert(addr)
                    if (!result.inserted) {
                        return nil // already in set
                    }
                }
                return CModuleSymbol.deserialize(from: dict)
            }
            return nil
        }
        switch type {
        case .exports: exportSymbols = objs;
        case .imports: importSymbols = objs;
        }
        reloadTable()
    }
    
    private func reloadTable() {
        numLabel.stringValue = "Total: \(showingSymbols.count)"
        self.tableView.reloadData()
    }
    
    
    @IBAction func onSegmentChange(_ sender: NSSegmentedControl) {
        if (sender.selectedSegment == 0) {
            loadSymbols(type: .exports)
        } else {
            loadSymbols(type: .imports)
        }
    }
}

extension CModuleSymbolViewController: NSTableViewDataSource, NSTableViewDelegate {
    
    var showingSymbols:[CModuleSymbol] {
        switch showingType {
        case .exports: return exportSymbols;
        case .imports: return importSymbols;
        }
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return showingSymbols.count;
    }
    
    fileprivate enum CellIdentifiers {
        static let AddressCell = "AddressCell"
        static let NameCell = "NameCell"
        static let TypeCell = "TypeCell"
        
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 20;
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        //var image: NSImage?
        var text: String = ""
        var cellIdentifier: String = ""
        
        // 1
        let symbol = showingSymbols[row];
        
        // 2
        if tableColumn == tableView.tableColumns[0] {
            text = symbol.address
            cellIdentifier = CellIdentifiers.AddressCell
        } else if tableColumn == tableView.tableColumns[1] {
            text = symbol.name;
            cellIdentifier = CellIdentifiers.NameCell
        } else if tableColumn == tableView.tableColumns[2] {
            text = symbol.type
            cellIdentifier = CellIdentifiers.TypeCell
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


