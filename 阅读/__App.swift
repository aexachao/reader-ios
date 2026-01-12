//
//  __App.swift
//  阅读
//
//  Created by Chris Li on 2025/10/21.
//

import SwiftUI

@main
struct __App: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // 禁用摇一摇撤销弹窗
        application.applicationSupportsShakeToEdit = false
        return true
    }
}
