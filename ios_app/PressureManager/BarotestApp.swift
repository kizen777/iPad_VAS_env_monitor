//
//  Untitled.swift
//  Barotest
//
//  Created by kizenMBP16 on 2025/12/13.
//

import SwiftUI

@main
struct BarotestApp: App {
    var body: some Scene {
        WindowGroup {
            BaroGraphView()   // ← ここを ContentView() から変更
        }
    }
}

