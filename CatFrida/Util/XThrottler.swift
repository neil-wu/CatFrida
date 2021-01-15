//
//  XThrottler.swift
//  CatFrida
//
//  Created by neilwu on 2021/1/13.
//  Copyright © 2021 nw. All rights reserved.
//

import Foundation

public final class XThrottler {
    
    private let queue: DispatchQueue = DispatchQueue.global(qos: .background)
    
    private var job: DispatchWorkItem = DispatchWorkItem(block: {})
    private var previousRun: Date = Date.distantPast
    private var maxInterval: TimeInterval
    private var fireLast: Bool
    public init(maxInterval: TimeInterval, fireLast: Bool = false) {
        self.maxInterval = maxInterval
        self.fireLast = fireLast
    }
    
    public func throttle(block: @escaping () -> ()) {
        
        job.cancel()
        job = DispatchWorkItem(){ [weak self] in
            self?.previousRun = Date()
            DispatchQueue.main.async {
                block()
            }
        }
        // 保证 maxInterval 内只运行一次
        let past: TimeInterval = Date().timeIntervalSince(previousRun)
        if (past > maxInterval) {
            queue.async(execute: job)
        } else if (fireLast) {
            let delay: TimeInterval = maxInterval - past
            queue.asyncAfter(deadline: .now() + Double(delay), execute: job)
        }
    }
    
    func disable() {
        job.cancel()
    }
    
    
    
}

