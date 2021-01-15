//
//  CAppInfoViewController.swift
//  CatFrida
//
//  Created by neilwu on 2020/7/21.
//  Copyright © 2020 nw. All rights reserved.
//

import Cocoa
import HandyJSON

class CAppInfoViewController: NSViewController, CAppDetailContentProtocol {

    @IBOutlet weak var infoTextField: NSTextField!
    @IBOutlet weak var pathTextField: NSTextField!
    @IBOutlet var textView: NSTextView!
    
    deinit {
        print("~~~ CAppInfoViewController")
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textView.font = Config.codeFont;
        infoTextField.isSelectable = true
        pathTextField.isSelectable = true
    }
    
    func setupData(appInspector: CAppInspector?) {
        appInspector?.call(rpc: .info, callback: { [weak self] (result: RpcResult<NSDictionary>) in
            switch(result) {
            case .success(let dict):
                self?.updateInfo(dict);
            case .error(let error):
                self?.textView.string = error.localizedDescription;
            }
        })
    }
    func clearData() {
        //
    }
    
    
    func updateInfo(_ dict: NSDictionary) {
        guard let info = CAppInfo.deserialize(from: dict) else {
            return
        }
        let infoStr: String = info.json.printableDesc()
        /*if let infoDict:NSDictionary = dict["json"] as? NSDictionary {
            infoStr = infoDict.printableDesc()
            
            let sortedKeys = infoDict.allKeys.sorted { (a, b) -> Bool in
                if let sa = a as? String, let sb = b as? String {
                    return sa < sb
                }
                return false
            }
            
            for key in sortedKeys {
                let val = infoDict[key]
                if let valDict = val as? NSDictionary {
                    infoStr += "\(key) = \(valDict.printableDesc())\n"
                } else {
                    let tmp: String = val as? String ?? ""
                    infoStr += "\(key) = \(tmp)\n"
                }
            }
        }*/
        
        infoTextField.stringValue = """
        Name: \(info.name)
        Bundle id: \(info.id)
        Version: \(info.version) \(info.semVer)
        Minimum OS: \(info.minOS)
        """
        
        pathTextField.stringValue = """
        Binary: \(info.binary)
        Bundle: \(info.bundle)
        Data: \(info.data)
        Tmp: \(info.tmp)
        """
        
        self.textView.string = "\n" + infoStr + "\n"
        
    }
    
    
}



struct CAppInfo: HandyJSON {
    var name: String = ""
    var id: String = ""
    var binary: String = ""
    var bundle: String = ""
    var minOS: String = ""
    var semVer: String = ""
    var version: String = ""
    var data: String = ""
    var tmp: String = ""
    var json: NSDictionary = [:]
}

