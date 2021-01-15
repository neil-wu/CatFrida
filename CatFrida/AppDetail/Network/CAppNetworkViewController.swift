//
//  CAppNetworkViewController.swift
//  CatFrida
//
//  Created by neilwu on 2020/7/24.
//  Copyright © 2020 nw. All rights reserved.
//

import Cocoa

final class CAppNetworkViewController: NSViewController, CAppDetailContentProtocol {

    @IBOutlet weak var rootSplitView: NSSplitView!
    
    @IBOutlet weak var detailView: NSView!
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var detailSegControl: NSSegmentedControl!
    @IBOutlet weak var detailTextView: NSTextView!
    @IBOutlet weak var detailTitle: NSTextField!
    
    private var requestList:[CMessagePayloadNetwork] {
        return self.appInspector?.cacheMsgNetwork ?? [];
    }
    private weak var appInspector: CAppInspector? = nil;
    private var throttlerReloadTable = XThrottler(maxInterval: 1, fireLast: true)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        self.detailSegControl.selectedSegment = 0;
        self.detailSegControl.target = self;
        self.detailSegControl.action = #selector(onSegChange)
        
        self.rootSplitView.delegate = self
        showDetailView = false;
        
        detailView.wantsLayer = true
        detailView.layer?.backgroundColor = NSColor.white.cgColor
        
        self.detailTextView.font = Config.codeFont;
        detailTitle.stringValue = "Only Support [Alamofire](A Swift HTTP networking library)"
    }
    
    func setupData(appInspector: CAppInspector?) {
        self.appInspector = appInspector;
        
        self.appInspector?.blockOnNetworkUpdate = { [weak self] in
            self?.throttlerReloadTable.throttle { [weak self] in
                DispatchQueue.main.async { [weak self] in
                    self?.tableView.reloadData();
                }
            }
        }
        DispatchQueue.main.async { [weak self] in
            self?.tableView.reloadData();
        }
    }
    func clearData() {
        self.throttlerReloadTable.disable()
        self.appInspector?.blockOnNetworkUpdate = nil;
        self.appInspector = nil;
    }
    
    var showDetailView: Bool = false {
        didSet {
            let isShowing = !self.detailView.isHidden;
            if (isShowing == showDetailView) {
                return;
            }
            if (showDetailView) {
                self.detailView.isHidden = false;
                self.rootSplitView.setPosition(300, ofDividerAt: 0)
            } else {
                self.detailView.isHidden = true;
                self.rootSplitView.setPosition(self.rootSplitView.frame.height - 30, ofDividerAt: 0)
            }
            //self.rootSplitView.adjustSubviews();
            self.rootSplitView.layoutSubtreeIfNeeded();
        }
    }
}

extension CAppNetworkViewController: NSTableViewDelegate, NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return requestList.count;
    }
    
    fileprivate enum CellIdentifiers {
        static let HttpMethodCell = "HttpMethodCell"
        static let URLCell = "URLCell"
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 20;
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        //var image: NSImage? = nil;
        var text: String = ""
        var cellIdentifier: String = ""
        
        let request:CMessagePayloadNetwork = requestList[row];
        // 2
        if tableColumn == tableView.tableColumns[0] {
            text = "\(row)"
            cellIdentifier = CellIdentifiers.HttpMethodCell;
        } else if tableColumn == tableView.tableColumns[1] {
            text = request.req;
            cellIdentifier = CellIdentifiers.URLCell
        }
        
        // 3
        let identifier = NSUserInterfaceItemIdentifier(cellIdentifier);
        if let cell = tableView.makeView(withIdentifier: identifier, owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = text
            //cell.imageView?.image = image;
            cell.toolTip = text;
            return cell
        }
        
        return nil;
    }
    
    func tableView(_ tableView: NSTableView, didClick tableColumn: NSTableColumn) {
        print("didClick", tableColumn)
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        //print("tableViewSelectionDidChange", notification)
        let isReq: Bool = detailSegControl.selectedSegment == 0
        //self.detailSegControl.selectedSegment = 0;
        self.showRequestDetail(isReq);
    }
    
    func showRequestDetail(_ isReq:Bool = false) {
        let selRow = self.tableView.selectedRow;
        guard let request: CMessagePayloadNetwork = self.requestList.nwOptionObj(at: selRow) else {
            showDetailView = false;
            return;
        }
        detailTitle.stringValue = request.url
        showDetailView = true;
        self.detailTextView.string = isReq ? request.req : request.rsp;
    }
    
    @objc func onSegChange() {
        showRequestDetail(self.detailSegControl.selectedSegment == 0)
    }
    
    @IBAction func onClearBtn(_ sender: Any) {
        DispatchQueue.main.async { [weak self] in
            let alert = NSAlert()
            alert.messageText = "Clear all?"
            //alert.informativeText = ""
            alert.alertStyle = NSAlert.Style.warning
            alert.addButton(withTitle: "OK")
            alert.addButton(withTitle: "Cancel")
            
            if let window = self?.view.window {
                alert.beginSheetModal(for: window) { [weak self] (rsp:NSApplication.ModalResponse) in
                    if (rsp == NSApplication.ModalResponse.alertFirstButtonReturn) {
                        self?.doClear();
                    }
                }
            } else {
                if (alert.runModal() == NSApplication.ModalResponse.alertFirstButtonReturn) {
                    self?.doClear();
                }
            }
            
        }
    }
    
    private func doClear() {
        appInspector?.clearNetworkMessage()
    }
}

extension CAppNetworkViewController: NSSplitViewDelegate {
    func splitView(_ splitView: NSSplitView, canCollapseSubview subview: NSView) -> Bool {
        if (view == self.detailView) {
            return true;
        }
        return false;
    }
}

