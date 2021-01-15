//
//  CAppInspector.swift
//  CatFrida
//
//  Created by neilwu on 2020/7/20.
//  Copyright © 2020 nw. All rights reserved.
//

import Foundation

protocol CAppInspectorDelegate {
    func onSessionDetach(reason: String);
    func onScriptLoaded(type: CScriptType, script: Script?, error:Error?);
    func onScriptMessageNormal(script: Script, message: CMessage);
    func onScriptMessageError(script: Script, message: CMessageError);
}

final class CAppInspector : ScriptDelegate, SessionDelegate {
    let device: Device;
    let app:ApplicationDetails
    
    private(set) var session: Session? = nil;
    var delegate: CAppInspectorDelegate? = nil;
    
    private(set) var scriptCache:[Int: Script] = [:];
    private var autoUnloadScriptKeys:Set<Int> = [];
    
    private(set) var defaultScript: Script? = nil;
    
    private var downloadTasks:[String: CDownloadTask] = [:]; // [session: task]
    
    
    private(set) var cacheMsgNetwork:[CMessagePayloadNetwork] = [];
    var blockOnNetworkUpdate: NWVoidBlock? = nil;
    
    init(device: Device, app:ApplicationDetails) {
        self.device = device;
        self.app = app;
    }
    
    func attach(block: @escaping NWSuccessBlock) {
        guard let pid = app.pid else {
            block(false)
            return;
        }
        device.delegate = self;
        device.attach( UInt(pid)) { [weak self] (result:() throws -> Session) in
            do {
                let session:Session = try result();
                session.delegate = self;
                self?.session = session;
                Log("attach success");
                block(true)
            } catch {
                Log("attach to pid \(pid) fail \(error.localizedDescription)")
                block(false)
            }
        }
    }
    func session(_ session: Session, didDetach reason: SessionDetachReason) {
        Log("didDetach, \(reason.description)")
        self.delegate?.onSessionDetach(reason: reason.description)
    }
    
    func loadScript(_ scriptType: CScriptType, autoUnload: Bool) {
        // if autounload enable, The Script will be unloaded after first message arrived.
        //Log("\(scriptType)")
        let content: String = scriptType.content;
        if (content.isEmpty) {
            Log("load script fail, content is empty")
            return;
        }
        session?.createScript(content, name: app.name) { [weak self] (result:() throws -> Script) in
            do {
                let script: Script = try result();
                
                let key:Int = script.hash;
                self?.scriptCache[key] = script;
                if (autoUnload) {
                    self?.autoUnloadScriptKeys.insert(key);
                }
                if (scriptType == CScriptType.defaultScript) {
                    self?.defaultScript = script;
                }
                script.delegate = self
                script.load { (result:() throws -> Bool) in
                    do {
                        let isok = try result();
                        Log("script load complete, key=\(key), isok=\(isok)");
                        self?.delegate?.onScriptLoaded(type: scriptType, script: script, error: nil);
                    } catch {
                        Log("load script fail \(error.localizedDescription)");
                        self?.delegate?.onScriptLoaded(type: scriptType, script: script, error: error as? Error);
                    }
                    
                }
                
            } catch {
                Log("createScript fail \(error.localizedDescription)");
                
                self?.delegate?.onScriptLoaded(type: scriptType, script: nil, error: error as? Error);
            }
        }
    }
    
    func loadDefaultScript() {
        self.loadScript(CScriptType.defaultScript, autoUnload: false)
    }
    
    func unloadScript(_ script: Script) {
        let key:Int = script.hash;
        Log("unload \(key)")
        self.autoUnloadScriptKeys.remove(key);
        self.scriptCache.removeValue(forKey: key);
        script.delegate = nil;
        script.unload { (result:() throws -> Bool) in
            if let isok = try? result() {
                Log("script unload complete, \(isok)")
            }
        }
        if (script == self.defaultScript) {
            self.defaultScript = nil;
            Log("defaultScript was unloaded")
        }
    }
    
    
    func getDownloadTask(of session: String) -> CDownloadTask? {
        return self.downloadTasks[session];
    }
    
    func downloadFile(path: String, to localUrl: URL, block: NWStringBlock? = nil) {
        
        call(rpc: .download(path: path)) {  [weak self] (result:RpcResult<NSDictionary>) in
            switch(result) {
            case .success(let obj):
                let size: Int64 = obj["size"] as? Int64 ?? 0;
                let session: String = obj["session"] as? String ?? "";
                let task = CDownloadTask(remote: path, size: size, session: session, localUrl: localUrl);
                task.openFile();
                self?.downloadTasks[session] = task;
                block?(session);
            case .error(let error):
                Log("downlaod fail, err \(error.localizedDescription)")
            }
        }
    }
    
    //MARK: Script Delegate
    func scriptDestroyed(_ script: Script) {
        let key = script.hash
        Log("\(key)")
        if (script == self.defaultScript) {
            self.defaultScript = nil;
            Log("defaultScript was destroyed");
        }
        
    }
    func script(_ script: Script, didReceiveMessage message: Any, withData data: Data?) {
        //Log("didReceiveMessage")
        
        // send('xxx') => { payload = "xxx"; type = send; }
        // console.log('yyy') => { payload = "yyy"; type = info; }
        var handled: Bool = false;
        let msgDict:NSDictionary? = message as? NSDictionary
        if let cmsg: CMessage = CMessage.deserialize(from: msgDict) {
            //self.delegate?.onScriptMessage(script: script, message: cmsg);
            //func onScriptMessageError(script: Script, message: CMessageError);
            if (cmsg.type == .error) {
                if let errMsg: CMessageError = CMessageError.deserialize(from: msgDict) {
                    handled = true;
                    self.delegate?.onScriptMessageError(script: script, message: errMsg);
                }
            } else {
                handled = self.handleMessagePayload(cmsg, data: data)
            }
        }
        
        
        let key:Int = script.hash;
        
        if (!handled) {
            print("[didReceiveMessage] script \(key), unhandled=>", message, data?.description ?? "nil");
        }
        
        if self.autoUnloadScriptKeys.contains(key) {
            Log("auto unload script \(key)")
            self.unloadScript(script);
        }
    }
    
    func handleMessagePayload(_ cmsg: CMessage, data: Data?)-> Bool {
        if cmsg.type == .log {
            let str: String = cmsg.strPayload ?? ""
            print("[agent log]" + str)
            return true
        }
        if let _ = cmsg.strPayload {
            return true;
        }
        
        if let dict = cmsg.dictPayload {
            if let payload = CMessagePayload.deserialize(from: dict) {
                if (payload.subject == .download) {
                    self.handleDownloadMessage(payload, data: data)
                } else if (payload.subject == .network) {
                    self.handleNetworkMessage(payload, data: data)
                } else {
                    print("unhnadle", payload)
                }
            }
            return true;
        }
        return false;
    }
    
    func handleDownloadMessage(_ payload: CMessagePayload, data: Data?) {
        //
        guard let task: CDownloadTask = self.downloadTasks[payload.session] else {
            return;
        }
        
        if (payload.event == .data) {
            task.write(data);
        } else if (payload.event == .end) {
            task.endWrite();
            print("download done", task.sessionid)
        } else if (payload.event == .start) {
            //
            print("download start", task.sessionid)
        }
    }
    
    func handleNetworkMessage(_ payload: CMessagePayload, data: Data?) {
        guard let msg = payload.network else {
            return;
        }
        self.cacheMsgNetwork.append(msg);
        self.blockOnNetworkUpdate?();
    }
    func clearNetworkMessage() {
        cacheMsgNetwork.removeAll()
        self.blockOnNetworkUpdate?();
    }
    
    func call<T:NSObject>(rpc: CAppRpc, callback: @escaping (RpcResult<T>) -> Void) {
        guard let script = self.defaultScript else {
            return;
        }
        let rpcFunc: RpcFunction = script.exports[dynamicMember: rpc.rpcFuncName]
        rpcFunc.dynamicallyCall(withArguments: rpc.rpcFuncArgs).onResult(as: T.self) { (result:RpcResult<T>) in
            DispatchQueue.main.async {
                callback(result)
            }
        }
    }
    
}

extension CAppInspector: DeviceDelegate {
    func deviceLost(_ device: Device) {
        Log("\(device.cfShowingName)")
    }
    func device(_ device: Device, didAddSpawn spawn: SpawnDetails) {
        Log("didAddSpawn, \(device.cfShowingName)")
    }
    func device(_ device: Device, didRemoveSpawn spawn: SpawnDetails) {
        Log("didRemoveSpawn, \(device.cfShowingName)")
    }
    func device(_ device: Device, didOutput data: Data, toFileDescriptor fd: Int, fromProcess pid: UInt) {
        
        Log("didOutput, \(device.cfShowingName)")
    }

}
