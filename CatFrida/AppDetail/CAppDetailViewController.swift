//
//  CDeviceViewController.swift
//  CatFrida
//
//  Created by neilwu on 2020/7/17.
//  Copyright © 2020 nw. All rights reserved.
//

import Foundation
import Cocoa

fileprivate enum Entrys {
    case iOS
    //case Android
    
    case info
    case module
    case document
    case network
    //case log
    case runtime
    case ui
    case custom
    
    static func rootEntrys()-> [Entrys] {
        return [.iOS]
    }
    
    static func childEntrys()-> [Entrys] {
        return [.info, .module, .document, .runtime, .ui, .network, .custom];
    }
    
    var title: String {
        switch self {
        case .iOS: return "iOS";
        //case .Android: return "Android";
            
        //ios sub
        case .info: return "Info";
        case .module: return "Module";
        case .document: return "Document";
        case .network: return "AlamofireNetwork";
        //case .log: return "Log";
        case .runtime: return "Runtime"
        case .ui: return "UI"
        case .custom: return "Custom";
        }
    }
}

protocol CAppDetailContentProtocol {
    func setupData(appInspector: CAppInspector?);
    func clearData();
}

final class CAppDetailViewController: NSViewController {
    
    
    @IBOutlet weak var entryOutlineView: NSOutlineView!
    @IBOutlet weak var contentView: NSView!
    
    private var _currentContentViewController: NSViewController? = nil;
    
    public var appInspector: CAppInspector? = nil;
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        self.entryOutlineView.floatsGroupRows = false;
        self.entryOutlineView.reloadData()

        NSAnimationContext.beginGrouping();
        NSAnimationContext.current.duration = 0;
        self.entryOutlineView.expandItem(Entrys.rootEntrys().first, expandChildren: true);
        NSAnimationContext.endGrouping();
        
    }
    
    deinit {
        print("~~~ CAppDetailViewController")
        self.releaseRes();
    }
    
    func releaseRes() {
        Log("")
        self.appInspector?.delegate = nil;
        self.appInspector = nil;
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    func loadInspector(device:Device, app:ApplicationDetails) {
        
        self.appInspector = CAppInspector(device: device, app: app);
        self.appInspector?.delegate = self;
        self.attach();
    }
    func attach() {
        Log("");
        self.updateUI(" [Wait attaching...]");
        self.showLoading(tip: nil)
        self.appInspector?.attach { [weak self] (isok) -> (Void) in
            self?.hideLoading(tip: nil)
            if (isok) {
                self?.appInspector?.loadDefaultScript();
            } else {
                Log("attach fail");
                self?.onSessionDetach(reason: "attach timeout");
            }
        }
    }
    
    
    func updateUI(_ suffix: String = "") {
        DispatchQueue.main.async {
            var title: String = "";
            if let inspector = self.appInspector {
                title = inspector.device.cfShowingName + "_" + inspector.app.name;
            }
            self.view.window?.title = title + suffix;
        }
    }
}


extension CAppDetailViewController: CAppInspectorDelegate {
    
    func onSessionDetach(reason: String) {
        Log("")
        DispatchQueue.main.async { [weak self] in
            self?.updateUI(" [Detached]");
            let alert = NSAlert()
            alert.messageText = "Session Detached (reason=\(reason))."
            alert.informativeText = "To continue, CatFrida needs attach again"
            alert.alertStyle = NSAlert.Style.warning
            alert.addButton(withTitle: "Attach")
            alert.addButton(withTitle: "Cancel")
            
            if let window = self?.view.window {
                alert.beginSheetModal(for: window) { [weak self] (rsp:NSApplication.ModalResponse) in
                    if (rsp == NSApplication.ModalResponse.alertFirstButtonReturn) {
                        self?.attach();
                    }
                }
            } else {
                if (alert.runModal() == NSApplication.ModalResponse.alertFirstButtonReturn) {
                    self?.attach();
                }
            }
            
        }
    }
    func onScriptLoaded(type: CScriptType, script: Script?, error:Error?) {
        let errStr: String = error?.localizedDescription ?? "";
        if (!errStr.isEmpty) {
            Log("load script fail, err=\(errStr)")
        }
        if (type == .defaultScript) {
            DispatchQueue.main.async {
                if (errStr.isEmpty) {
                    self.updateUI(" [Attached]");
                    // select default
                    self.entryOutlineView.selectRowIndexes(IndexSet(integer: 1), byExtendingSelection: false)
                }
            }
        }
    }
    func onScriptMessageNormal(script: Script, message: CMessage) {
        //
    }
    func onScriptMessageError(script: Script, message: CMessageError) {
        //
    }
}



extension CAppDetailViewController: NSOutlineViewDataSource, NSOutlineViewDelegate {
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        //print("numberOfChildrenOfItem", item)
        if (nil == item) {
            return Entrys.rootEntrys().count;
        }
        return Entrys.childEntrys().count;
    }
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        if (outlineView.parent(forItem: item) == nil) {
            return true;
        }
        return false;
    }
    func outlineView(_ outlineView: NSOutlineView, shouldExpandItem item: Any) -> Bool {
        return true;
    }
    func outlineView(_ outlineView: NSOutlineView, isGroupItem item: Any) -> Bool {
        if let entry = item as? Entrys {
            return Entrys.rootEntrys().contains(entry)
        }
        return false;
    }
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if (nil == item) {
            return Entrys.rootEntrys()[index];
        }
        return Entrys.childEntrys()[index];
    }
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let entry = item as? Entrys else {
            return nil;
        }
        let title: String = entry.title;
        
        if Entrys.rootEntrys().contains(entry) {
            let cell: NSTableCellView? = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "HeaderCell"), owner: self) as? NSTableCellView;
            cell?.textField?.stringValue = title;
            return cell;
        }
        
        let dataCell:NSTableCellView? = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "DataCell"), owner: self) as? NSTableCellView;
        dataCell?.textField?.stringValue = title;
        
        
        return dataCell;
    }
    
    
    func outlineViewSelectionDidChange(_ notification: Notification) {
        showSelectedOutline()
    }
    
    private func showSelectedOutline() {
        guard let item = self.entryOutlineView.item(atRow: self.entryOutlineView.selectedRow) as? Entrys else {
            return;
        }
        
        if (self.appInspector?.session == nil) {
            Log("waiting session attaching")
            return;
        }
        
        if (nil != _currentContentViewController) {
            
            if let proto = _currentContentViewController as? CAppDetailContentProtocol {
                proto.clearData();
            }
            _currentContentViewController?.view.removeFromSuperview();
            _currentContentViewController = nil;
        }
        _currentContentViewController = makeContentView(item);
        if let view = _currentContentViewController?.view {
            view.frame = self.contentView.bounds;
            //view// = NSViewWidthSizable | NSViewHeightSizable;
            view.autoresizingMask = [NSView.AutoresizingMask.width, NSView.AutoresizingMask.height];
            self.contentView.addSubview(view);
        }
        if let proto = _currentContentViewController as? CAppDetailContentProtocol {
            if let appInspec = self.appInspector {
                proto.setupData(appInspector: appInspec);
            }
        }
    }
    
    
    fileprivate func makeContentView(_ entry: Entrys)-> NSViewController? {
        switch entry {
        case .info: return CAppInfoViewController();
        case .module: return CAppModuleViewController();
        case .document: return CAppDocumentViewController();
        case .network: return CAppNetworkViewController();
        case .runtime: return CAppRuntimeViewController()
        case .ui: return CAppUIViewController()
        case .custom: return CAppCustomScriptViewController();
        default:
            return nil;
        }
    }
    
}





