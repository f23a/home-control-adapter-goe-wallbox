//
//  HomeControlAdapterGoeWallboxApp.swift
//  HomeControlAdapterGoeWallbox
//
//  Created by Christoph Pageler on 29.09.24.
//

import SwiftUI

@main
struct HomeControlAdapterGoeWallboxApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .fixedSize()
        }
        .windowResizability(.contentSize)
    }
}
