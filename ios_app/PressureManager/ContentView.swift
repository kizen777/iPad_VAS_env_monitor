//
//  ContentView.swift
//  PressureManager
//
//  Created by kizenMBP16 on 2025/12/13.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var pressureManager = PressureManager()
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Barotest : 気圧テスト")
                .font(.title)
            
            if let p = pressureManager.latestPressure {
                Text(String(format: "現在の気圧: %.1f hPa", p))
                   // .font(.largeTitle)
                    .font(.title2)
                    .fontWeight(.bold)
            } else {
                Text("現在の気圧: 取得中…")
                    .font(.title2)
            }
        }
        .padding()
        .onAppear {
            pressureManager.start()
        }
        .onDisappear {
            pressureManager.stop()
        }
    }
}

#Preview {
    ContentView()
}


