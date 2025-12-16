import SwiftUI
import CoreMotion
import Charts
import Combine

struct BaroSample: Identifiable {
    let id = UUID()
    let time: Date
    let pressureHpa: Double
    let isRapid: Bool
}

struct FiveMinSample {
    let time: Date
    let pressureHpa: Double
}

final class BaroViewModel: ObservableObject {
    @Published var samples: [BaroSample] = []
    @Published var fiveMinPoints: [FiveMinSample] = []

    private let altimeter = CMAltimeter()
    private let queue = OperationQueue()
    
    // 現在気圧表用
    var currentPressure: Double? {
        samples.last?.pressureHpa
    }
    
    // 画面に表示する時間幅（秒）
    private let visibleDuration: TimeInterval = 60 * 60  // 60分

    // MARK: - Public

    func start() {
        guard CMAltimeter.isRelativeAltitudeAvailable() else { return }

        altimeter.startRelativeAltitudeUpdates(to: queue) { [weak self] data, error in
            guard let self, let data else { return }

            let hpa = data.pressure.doubleValue * 10.0   // kPa -> hPa
            let now = Date()

            DispatchQueue.main.async {
                self.appendSample(time: now, pressureHpa: hpa)
                self.trimOldSamples(now: now)
                self.updateFiveMinPointIfNeeded(now: now, pressureHpa: hpa)
            }
        }
    }

    func stop() {
        altimeter.stopRelativeAltitudeUpdates()
    }

    // 表示用: 最新 visibleDuration 分だけ
    var visibleSamples: [BaroSample] {
        guard let latest = samples.last?.time else { return samples }
        let from = latest.addingTimeInterval(-visibleDuration)
        return samples.filter { $0.time >= from }
    }

    var visibleFiveMinPoints: [FiveMinSample] {
        guard let latest = samples.last?.time else { return fiveMinPoints }
        let from = latest.addingTimeInterval(-visibleDuration)
        return fiveMinPoints.filter { $0.time >= from }
    }

    // MARK: - Private

    private func appendSample(time: Date, pressureHpa: Double) {
        // 5分前のサンプルを探す
        let fiveMinBefore = time.addingTimeInterval(-5 * 60)
        let nearestPrev = samples
            .filter { abs($0.time.timeIntervalSince(fiveMinBefore)) < 60 }
            .min(by: { abs($0.time.timeIntervalSince(fiveMinBefore)) <
                       abs($1.time.timeIntervalSince(fiveMinBefore)) })

        let isRapidChange: Bool
        if let prev = nearestPrev {
            let diff = pressureHpa - prev.pressureHpa
            isRapidChange = abs(diff) >= 6.0    // ±6 hPa 以上
        } else {
            isRapidChange = false
        }

        let sample = BaroSample(time: time,
                                pressureHpa: pressureHpa,
                                isRapid: isRapidChange)
        samples.append(sample)
    }

    private func trimOldSamples(now: Date) {
        let from = now.addingTimeInterval(-visibleDuration * 2) // バッファを少し余分に保持
        samples.removeAll { $0.time < from }
        fiveMinPoints.removeAll { $0.time < from }
    }

    private func updateFiveMinPointIfNeeded(now: Date, pressureHpa: Double) {
        // 「5分毎時」：分を 0,5,10,... に丸めた時間をキーにする
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: now)

        guard let minute = comps.minute,
              let roundedMinute = (minute / 5) * 5 as Int?,
              let roundedDate = calendar.date(from: DateComponents(
                  year: comps.year,
                  month: comps.month,
                  day: comps.day,
                  hour: comps.hour,
                  minute: roundedMinute
              )) else {
            return
        }

        // すでにこの「5分刻み時刻」があれば上書き、なければ追加
        if let index = fiveMinPoints.firstIndex(where: { abs($0.time.timeIntervalSince(roundedDate)) < 60 }) {
            fiveMinPoints[index] = FiveMinSample(time: roundedDate, pressureHpa: pressureHpa)
        } else {
            fiveMinPoints.append(FiveMinSample(time: roundedDate, pressureHpa: pressureHpa))
        }
    }
}

struct BaroGraphView: View {
    @StateObject private var viewModel = BaroViewModel()
    
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy/MM/dd EEE"   // 例: 2025/12/14 Sun
        return f
    }()
    
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            // 日付
            Text(dateFormatter.string(from: Date()))
                .font(.caption.bold())

            // 現在の気圧（あれば表示）
            if let p = viewModel.currentPressure {
                Text("     現在気圧:")
                    .font(.caption.bold())
                Text(String(format: "%.1f hPa", p))
                    .font(.caption.bold())   // 大きめの数字
            }

            Spacer()
        }
        .padding(.horizontal, 8)


            // グラフ本体
            Chart {
                // ここは元のコードそのまま
                ForEach(viewModel.visibleSamples) { sample in
                    LineMark(
                        x: .value("Time", sample.time),
                        y: .value("Pressure", sample.pressureHpa)
                    )
                    .foregroundStyle(sample.isRapid ? .red : .blue)
                }

                ForEach(viewModel.visibleFiveMinPoints, id: \.time) { point in
                    PointMark(
                        x: .value("Time", point.time),
                        y: .value("5min", point.pressureHpa)
                    )
                    .symbol(.circle)
                    .foregroundStyle(.green)
                    .annotation(position: .top, alignment: .center) {
                        Text(String(format: "%.1f", point.pressureHpa))
                            .font(.caption.bold())
                            .foregroundColor(.primary)
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic) { value in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.hour().minute())
                }
            }
            .chartYScale(domain: 950...1100)
            .chartYAxisLabel {
                Text("Pressure (hPa)")
                    .font(.caption.bold())
                    .frame(height: 0) // グラフ表示幅調整
            }
            .chartYAxis {
                AxisMarks(values: .automatic)
            }
            .padding()

            // 日付 グラフ下段　テスト時 コメントアウトしておく
//            HStack {
//                Text(dateFormatter.string(from: Date()))
//                    .font(.caption.bold())
//                Spacer()
//            }
//            .padding(.horizontal, 8)

            // Start / Stop ボタン
            HStack(spacing: 40) {
                Button("Start") {
                    viewModel.start()
                }
                .font(.title3.bold())

                Button("Stop") {
                    viewModel.stop()
                }
                .font(.title3.bold())
                .foregroundColor(.red)
            }
            .padding(.top, 16)
        }
    }

