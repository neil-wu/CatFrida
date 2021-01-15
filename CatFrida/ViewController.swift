//
//  ViewController.swift
//  CatFrida
//
//  Created by neilwu on 2020/7/16.
//  Copyright © 2020 nw. All rights reserved.
//

import Cocoa

fileprivate enum AppOrder: String {
    case name = "name"
    case bundleid = "bundleid"
    case pid = "pid"
}


class ViewController: NSViewController, NSComboBoxDelegate, NSSearchFieldDelegate {

    enum SegueID : String {
        case ShowDetail = "ShowDetail"
        
        var identifier:NSStoryboardSegue.Identifier {
            return NSStoryboardSegue.Identifier.init("ShowDetail")
        }
    }
    
    @IBOutlet weak var deviceTip: NSTextField!
    @IBOutlet weak var deviceComboBox: NSComboBox!
    @IBOutlet weak var refreshDeviceBtn: NSButton!
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var searchField: NSSearchField!
    @IBOutlet weak var attachFrontmostBtn: NSButton!
    @IBOutlet weak var showSysBtn: NSButton!
    @IBOutlet weak var numLabel: NSTextField!
    
    private var showSysApps: Bool {
        return showSysBtn.integerValue == 1
    }
    
    fileprivate var deviceApps:[ApplicationDetails] = []; //未过滤的全部app
    fileprivate var showingApps:[ApplicationDetails] = [] {
        didSet {
            numLabel.stringValue = "Total: \(showingApps.count)"
        }
    }
    fileprivate var sortOrder: AppOrder = AppOrder.name;
    fileprivate var sortAscending: Bool = true;
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.deviceComboBox.delegate = self;
        self.deviceComboBox.isEditable = false;
        
        self.tableView.delegate = self;
        self.tableView.dataSource = self;
        self.tableView.target = self;
        self.tableView.doubleAction = #selector(onDoubleClickTable);

        let descriptorName = NSSortDescriptor(key: AppOrder.name.rawValue, ascending: true)
        let descriptorDate = NSSortDescriptor(key: AppOrder.bundleid.rawValue, ascending: true)
        let descriptorSize = NSSortDescriptor(key: AppOrder.pid.rawValue, ascending: true)
        tableView.tableColumns[0].sortDescriptorPrototype = descriptorName
        tableView.tableColumns[1].sortDescriptorPrototype = descriptorDate
        tableView.tableColumns[2].sortDescriptorPrototype = descriptorSize
                
        doRefreshDevices();
        
        searchField.delegate = self
        searchField.resignFirstResponder()
        
    }

    @IBAction func onSearchField(_ sender: NSSearchField) {
        Log("search sender.stringValue")
        
        let str: String = sender.stringValue
        guard !str.isEmpty else {
            return
        }
        
        let showSys = showSysApps;
        let result = deviceApps.filter { (app) -> Bool in
            if app.cfIsAppleSysApp && !showSys {
                return false
            }
            return app.cfContains(str: str)
        }
        
        self.showingApps = result
        self.tableView.reloadData()
        if result.isEmpty {
            self.toast("Empty result")
        }
    }
    
    func searchFieldDidEndSearching(_ sender: NSSearchField) {
        //print("end search")
        updateShowingApps()
    }
    
    private func doRefreshDevices() {
        Log("")
        CFridaHelper.shared.refreshDevices { [weak self] (isok) -> (Void) in
            if (isok) {
                self?.updateDevices();
            }
        }
    }
    
    private func updateDevices() {
        let names:[String] = CFridaHelper.shared.devices.map { (device:Device) -> String in
            return device.cfShowingName;
        }
        self.deviceComboBox.removeAllItems();
        self.deviceComboBox.addItems(withObjectValues: names);
        
        if (names.count >= 1) {
            self.deviceComboBox.selectItem(at: 0)
        }
    }
    func comboBoxSelectionDidChange(_ notification: Notification) {
        let selIndex = self.deviceComboBox.indexOfSelectedItem;
        Log("selIndex \(selIndex)")
        CFridaHelper.shared.getApplicationsOf(deviceIdx: selIndex) { [weak self] (result:[ApplicationDetails]) -> (Void) in
            self?.deviceApps = result;
            self?.showingApps = result.filter{ !$0.cfIsAppleSysApp }
            self?.tableView.reloadData();
        }
    }
    
    @IBAction func onRefreshBtn(_ sender: Any) {
        
        doRefreshDevices();
    }
    
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


    
    @IBAction func onShowAppleApp(_ sender: NSButton) {
        //print(sender, sender.integerValue)
        updateShowingApps()
    }
    private func updateShowingApps() {
        if (showSysApps) {
            self.showingApps = self.deviceApps;
        } else {
            self.showingApps = self.deviceApps.filter{ !$0.cfIsAppleSysApp }
        }
        self.tableView.reloadData();
    }
    
    @IBAction func onAttachFrontmost(_ sender: Any) {
        self.attachFrontmostBtn.isEnabled = false;
        let selIndex = self.deviceComboBox.indexOfSelectedItem;
        CFridaHelper.shared.getFrontmostApp(deviceIdx: selIndex) { [weak self] (result:[ApplicationDetails]) -> (Void) in
            self?.attachFrontmostBtn.isEnabled = true;
            if let app = result.first {
                print("app \(app)")
                self?.openApp(app);
            } else {
                showAlert(question: "fail to get frontmost app!", text: "")
            }
        }
    }
    
    func openApp(_ app: ApplicationDetails) {
        guard let pid = app.pid else {
            toast("App must running foreground")
            return;
        }
        Log("openApp, pid \(pid)");
        
        
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: SegueID.ShowDetail.identifier, sender: app)
        }
        
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender);
        
        
        if let detailWin = segue.destinationController as? CAppDetailWindow,
            let detailVC = detailWin.contentViewController as? CAppDetailViewController {
            
            let selIndex = self.deviceComboBox.indexOfSelectedItem;
            if let device = CFridaHelper.shared.getDevice(at: selIndex),
                let app:ApplicationDetails = sender as? ApplicationDetails {
                detailVC.loadInspector(device: device, app: app)
            } else {
                Log("fail to load inspector")
            }
        }
    }
}

extension ViewController: NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return showingApps.count;
    }
    
    fileprivate enum CellIdentifiers {
        static let NameCell = "NameCellID"
        static let BundleIDCell = "BundleIDCellID"
        static let PidCell = "PidCellID"
    }
    func reloadAppList() {
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
            
        })
        tableView.reloadData()
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 30;
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        var image: NSImage?
        var text: String = ""
        var cellIdentifier: String = ""
        
        // 1
        let appDetail:ApplicationDetails = showingApps[row];
        
        // 2
        if tableColumn == tableView.tableColumns[0] {
            image = appDetail.smallIcon
            text = appDetail.name
            cellIdentifier = CellIdentifiers.NameCell
        } else if tableColumn == tableView.tableColumns[1] {
            text = appDetail.identifier;
            cellIdentifier = CellIdentifiers.BundleIDCell
        } else if tableColumn == tableView.tableColumns[2] {
            if let pid = appDetail.pid {
                text = "\(pid)"
            } else {
                text = "-"
            }
            cellIdentifier = CellIdentifiers.PidCell;
        }
        
        // 3
        let identifier = NSUserInterfaceItemIdentifier(cellIdentifier);
        if let cell = tableView.makeView(withIdentifier: identifier, owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = text
            cell.imageView?.image = image
            return cell
        }
        
        return nil;
    }
    func tableView(_ tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
        guard let sortDescriptor = tableView.sortDescriptors.first else {
            return
        }
        if let order = AppOrder(rawValue: sortDescriptor.key ?? "") {
            self.sortOrder = order;
            self.sortAscending = sortDescriptor.ascending;
            self.reloadAppList();
        }
        
    }
    
    @objc func onDoubleClickTable() {
        /*
        // 1
        guard tableView.selectedRow >= 0,
            let item = directoryItems?[tableView.selectedRow] else {
                return
        }
        */
        let selectedRow = self.tableView.selectedRow;
        Log("selectedRow \(selectedRow)");
        guard let app = self.showingApps.nwOptionObj(at: selectedRow) else {
            return;
        }
     
        self.openApp(app);
        
        
        #if DEBUG
        //CFridaHelper.shared.addRemoteDevie(ip: "127.0.0.1", port: 27042)
        
        /*
        let selIndex = self.deviceComboBox.indexOfSelectedItem;
        let device: Device? = CFridaHelper.shared.getDevice(at: selIndex);
        
        device?.enableSpawnGating({ (result:() throws -> Bool) in
            do {
                let ret = try result();
                Log("enableSpawnGating success, ret \(ret)")
                
                
            } catch {
                Log("enableSpawnGating fail, error \(error)")
            }
        })
        */
        
        /*
        device?.spawn(app.identifier, completionHandler: { (result:() throws -> UInt) in
            do {
                let ret = try result();
                Log("spawn success, ret \(ret)")
            } catch {
                Log("spawn fail, error \(error)")
            }
        })*/
        #endif
        
    }
    
    
    
}







