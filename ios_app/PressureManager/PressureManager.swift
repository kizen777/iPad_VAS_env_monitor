//
//  PressureManagerApp.swift
//  PressureManager
//
//  Created by kizenMBP16 on 2025/12/13.
//

import Foundation
import Combine
import CoreMotion

final class PressureManager: ObservableObject {
    private let altimeter = CMAltimeter()
    
    // 最新の気圧（hPa）
    @Published var latestPressure: Double?
    
    func start() {
        // この端末で気圧が取れない場合は何もしない
        guard CMAltimeter.isRelativeAltitudeAvailable() else {
            return
        }
        
        altimeter.startRelativeAltitudeUpdates(to: .main) { [weak self] data, error in
            guard let self,
                  error == nil,
                  let pressureNumber = data?.pressure else {
                return
            }
            // pressure は kPa (NSNumber) → Double → hPa
            let pressureKPa = pressureNumber.doubleValue
            let pressureHPa = pressureKPa * 10.0
            self.latestPressure = pressureHPa
        }
    }
    
    func stop() {
        altimeter.stopRelativeAltitudeUpdates()
    }
}
