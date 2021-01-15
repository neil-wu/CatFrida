//
//  CFridaHelper.swift
//  CatFrida
//
//  Created by neilwu on 2020/7/17.
//  Copyright © 2020 nw. All rights reserved.
//

import Foundation


typealias NWAppDetailsArrayBlock = ([ApplicationDetails]) ->(Void);

final class CFridaHelper {
    static let shared: CFridaHelper = CFridaHelper();
    
    private(set) lazy var deviceManager = DeviceManager();
    private(set) var devices:[Device] = [];
    
    func refreshDevices(block: NWSuccessBlock? = nil) {
        
        deviceManager.enumerateDevices { [weak self] (result: () throws -> [Device]) in
            do {
                let devices:[Device] = try result()
                self?.devices = devices.sorted(by: { (da, db) -> Bool in
                    return (da.kind == Device.Kind.usb);
                })
                block?(true);
            } catch {
                Log("fail to get devices, err=\(error.localizedDescription)")
                block?(false);
            }
        }
    }
    
    func getApplicationsOf(deviceIdx: Int,  block: @escaping NWAppDetailsArrayBlock) {
        guard deviceIdx >= 0 && deviceIdx < self.devices.count else {
            return;
        }
        let device = self.devices[deviceIdx];
        device.enumerateApplications { (result: () throws -> [ApplicationDetails]) in
            do {
                let detail = try result();
                block(detail);
            } catch {
                Log("fail to get Applications, err=\(error.localizedDescription)")
                block([]);
            }
        }
    }
    
    func getFrontmostApp(deviceIdx:Int,  block: @escaping NWAppDetailsArrayBlock) {
        guard deviceIdx >= 0 && deviceIdx < self.devices.count else {
            return;
        }
        let device = self.devices[deviceIdx];
        device.getFrontmostApplication({ (result: () throws -> ApplicationDetails?) in
            do {
                if let detail = try result() {
                    block([detail]);
                } else {
                    block([]);
                }
            } catch {
                let err: String = "fail to getFrontmostApp, err=\(error.localizedDescription)"
                Log(err)
                block([]);
            }
            
        })
    }
    
    func getDevice(at idx: Int) -> Device? {
        return self.devices.nwOptionObj(at: idx);
    }
    
    func addRemoteDevie(ip: String, port: Int) {
        let addr: String = "\(ip):\(port)"
        deviceManager.addRemoteDevice(addr) { (result: () throws -> Device) in
            do {
                let device = try result()
                print("device", device)
            } catch {
                let err: String = "fail to add remote device \(addr), err=\(error.localizedDescription)"
                Log(err)
            }
        }
    }
}

