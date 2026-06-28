//
//  DigitalFileCleanupApp.swift
//  DigitalFileCleanup
//
//  Created by Ghailen Ben Othman on 28/06/2026.
//

import SwiftUI

@main
struct DigitalFileCleanupApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 900, idealWidth: 1200, minHeight: 600, idealHeight: 800)
        }
        .windowResizability(.contentSize)
    }
}
