//
//  CAppUIViewController.swift
//  CatFrida
//
//  Created by neilwu on 2021/1/12.
//  Copyright © 2021 nw. All rights reserved.
//

import Cocoa

final class CAppUIViewController: NSViewController, CAppDetailContentProtocol {

    private var appInspector: CAppInspector? = nil
    @IBOutlet weak var outlineView: NSOutlineView!
    @IBOutlet weak var detailLabel: NSTextField!
    
    private var rootNodes: [CAppViewNode] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        outlineView.delegate = self
        outlineView.dataSource = self
        
        detailLabel.isSelectable = true
        detailLabel.stringValue = ""
    }
    
    func setupData(appInspector: CAppInspector?) {
        self.appInspector = appInspector
        appInspector?.call(rpc: .dumpWindow, callback: { [weak self] (result: RpcResult<NSString>) in
            switch(result) {
            case .success(let nsstr):
                //print("ui->", str)
                let str: String = nsstr as String
                self?.parseUI(str)
            case .error(let error):
                self?.toast("fail to get UI, \(error.localizedDescription)")
            }
        })
    }
    func clearData() {
        appInspector = nil
    }
    
    
    private func parseUI(_ str: String) {
        if (str.isEmpty) {
            return
        }
        let root = parseNode(str)
        if root.isEmpty {
            self.toast("parse fail")
            return
        }
        rootNodes = root
        
        //self.outlineView.floatsGroupRows = false;
        self.outlineView.reloadData()
        
        NSAnimationContext.beginGrouping();
        NSAnimationContext.current.duration = 0;
        self.outlineView.expandItem(rootNodes.first, expandChildren: true);
        NSAnimationContext.endGrouping();
        
    }
    
    func parseNode(_ resultStr: String) -> [CAppViewNode] {
        let lines:[String] = resultStr.split(separator: "\n").map{ String($0)}
        //print("lines", lines.count)
        
        var rootNodes: [CAppViewNode] = []
        var stack:[CAppViewNode] = []
        var preDepth: Int = -1
        for line in lines {
            if (line.isEmpty) {
                continue
            }
            guard let node: CAppViewNode = CAppViewNode.buildFrom(line: line) else {
                return []
            }
            
            if ( node.depth == 0 ){
                // root node
                preDepth = node.depth
                rootNodes.append(node)
                
                stack.removeAll() // reset
                stack.append(node) // root node
                continue
            }
            
            if (node.depth > preDepth) {
                stack.last?.children.append(node)
                stack.append(node)
            } else if (node.depth == preDepth) {
                _ = stack.popLast()
                if let lastParent = stack.last {
                    lastParent.children.append(node)
                }
                stack.append(node)
            } else if (node.depth < preDepth) {
                let k: Int = (stack.count - node.depth)
                stack.removeLast(k)
                stack.last?.children.append(node)
                stack.append(node)
            }
            preDepth = node.depth
        }
        
        return rootNodes
    }
    
}

extension CAppUIViewController: NSOutlineViewDataSource, NSOutlineViewDelegate {
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        
        if let node = item as? CAppViewNode {
            return node.children.count
        }
        return rootNodes.count
    }
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        if let node = item as? CAppViewNode {
            return node.children.count > 0
        }
        return false;
    }
    func outlineView(_ outlineView: NSOutlineView, shouldExpandItem item: Any) -> Bool {
        return true;
    }
    func outlineView(_ outlineView: NSOutlineView, isGroupItem item: Any) -> Bool {
        if let node = item as? CAppViewNode {
            return node.depth == 0 // root node
        }
        return false;
    }
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if (nil == item) {
            return rootNodes[index]
        }
        let node = item as! CAppViewNode
        return node.children[index]
    }
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let node = item as? CAppViewNode else {
            return nil;
        }
        let title: String = node.desc;
        
        let dataCell:NSTableCellView? = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "DataCell"), owner: self) as? NSTableCellView;
        dataCell?.textField?.stringValue = title;
        dataCell?.toolTip = title
        
        return dataCell;
    }
    func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
        return 24
    }
    
    func outlineViewSelectionDidChange(_ notification: Notification) {
        showSelectedOutline()
    }
    
    private func showSelectedOutline() {
        guard let node = outlineView.item(atRow: outlineView.selectedRow) as? CAppViewNode else {
            return;
        }
        detailLabel.stringValue = node.desc
    }
    
    
}
