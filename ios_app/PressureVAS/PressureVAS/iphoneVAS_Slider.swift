import SwiftUI

// 右肩上がりの三角定規バー
struct TriangularVASBar: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        // 左下 → 右下 → 右上（右肩上がり）
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))    // 左下
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY)) // 右下
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY)) // 右上
        path.closeSubpath()
        return path
    }
}

struct ContentView: View {
    // 設定を保存する
    @AppStorage("isNonBiasMode") private var isNonBiasMode: Bool = false
    
    // スライダー位置（0.0〜100.0）
    @State private var vasValue: Double = 50.0
    // VAS値を一時的に表示しているか
    @State private var isShowingValue: Bool = false
    // 記録中かどうか
    @State private var isRecording: Bool = false
    // 検者用シート表示フラグ
    @State private var isShowingExaminerSheet: Bool = false

    // 端末ごとに長さを変える VAS 幅
    private var vasWidth: CGFloat {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return 600   // iPad
        } else {
            return 530   // iPhone 15 Pro Max
        }
    }

    // 高さの設定値（175のまま維持）
    private let triangleHeight: CGFloat = 175
    
    // 署名用の濃い青色を定義
    private let darkSignatureBlue = Color(red: 0.0, green: 0.0, blue: 0.4)

    var isPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }

    var body: some View {
        // 全体を包むGeometryReaderで座標系を統一
        GeometryReader { geo in
            ZStack {
                // ==========================================
                // レイヤー0：隠し署名（最背面）
                // ==========================================
                Text("Kizen Sasaki")
                    // Zから始まる筆記体フォント(Zapfino)、サイズ7pt
                    .font(.custom("Zapfino", size: 7))
                    // 記録ボタンより濃い青
                    .foregroundColor(darkSignatureBlue)
                    // 画面最下部ギリギリに配置
                    .position(x: geo.size.width / 2, y: geo.size.height + 7)
                    .zIndex(0)

                // ==========================================
                // レイヤー1：上部タイトル（位置固定）
                // ==========================================
                VStack {
                    Text("今の痛みの強さをスライダーを示してください")
                        .font(.title)
                        .multilineTextAlignment(.center)
                        .padding(.top, 31) // 上から31pt固定
                    Spacer()
                }
                .zIndex(1)

                // ==========================================
                // レイヤー2：VASスライダー（中央）
                // ==========================================
                VStack(spacing: 0) {
                    
                    // ① 上段：絵文字（ノンバイアス時は透明化）
                    ZStack {
                        Text("😀")
                            .font(.system(size: 60))
                            .position(x: 0, y: 80 - 15)
                        Text("😫")
                            .font(.system(size: 60))
                            .position(x: vasWidth, y: 80 - 15)
                    }
                    .frame(width: vasWidth, height: 80)
                    .opacity(isNonBiasMode ? 0 : 1)
                    
                    // ② 三角定規＋ガイド
                    ZStack {
                        TriangularVASBar()
                            .fill(Color.blue.opacity(0.3))
                        
                        // 青いバー
                        let xPos = CGFloat(vasValue / 100.0) * vasWidth
                        Rectangle()
                            .fill(Color.blue)
                            .frame(width: 4, height: triangleHeight + 40)
                            .position(x: xPos, y: triangleHeight / 2)
                    }
                    .frame(width: vasWidth, height: triangleHeight)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let width = vasWidth
                                let clampedX = min(max(0, value.location.x), width)
                                vasValue = Double(clampedX / width) * 100.0
                            }
                    )
                    
                    // ③ 下段：文字ラベル（ノンバイアス時は透明化）
                    ZStack {
                        Text("全く痛くない")
                            .font(.system(size: isPhone ? 20 : 28, weight: .bold))
                            .position(x: 0, y: 30)
                        Text("耐えられないほど痛い")
                            .font(.system(size: isPhone ? 20 : 28, weight: .bold))
                            .position(x: vasWidth, y: 30)
                    }
                    .frame(width: vasWidth, height: 60)
                    .opacity(isNonBiasMode ? 0 : 1)
                }
                // 画面中央に配置しつつ、オフセット(3pt)で位置調整
                .position(x: geo.size.width / 2, y: geo.size.height / 2 + 3)
                .zIndex(2)

                // ==========================================
                // レイヤー3：VAS数値の表示（条件付き表示）
                // ==========================================
                if isShowingValue {
                    Text("\(Int(vasValue))")
                        .font(.system(size: 80, weight: .bold))
                        .padding(10)
                        .background(Color.white.opacity(0.6))
                        .cornerRadius(10)
                        // 前回位置(下から190pt)を維持
                        .position(x: geo.size.width / 2, y: geo.size.height - 190)
                        .zIndex(3)
                }

                // ==========================================
                // レイヤー4：記録ボタン（位置固定）
                // ==========================================
                Button {
                    guard !isRecording else { return }
                    
                    isRecording = true
                    isShowingValue = true
                    
                    // 10秒待って記録
                    DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                        saveVAS(value: vasValue)
                        isShowingValue = false
                        isRecording = false
                        vasValue = 50.0
                    }
                } label: {
                    Text(isRecording ? "記録しています…" : "記録")
                        .font(.system(size: 32, weight: .bold))
                        .padding(.vertical, 10)
                        .frame(width: geo.size.width - 260 * 2)
                        .background(isRecording ? Color.white : Color.blue)
                        .foregroundColor(isRecording ? Color.blue : Color.white)
                        .cornerRadius(12)
                }
                // ▼▼▼ 修正：下からの位置を 32 → 35 に変更（1mm上へ） ▼▼▼
                .position(x: geo.size.width / 2, y: geo.size.height - 35)
                .zIndex(4)

                // ==========================================
                // レイヤー5：右上の「隠し」検者ボタン（位置固定）
                // ==========================================
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            isShowingExaminerSheet = true
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .resizable()
                                .frame(width: 40, height: 40)
                                .foregroundColor(Color.gray.opacity(0.4))
                                .background(Color.white.opacity(0.3))
                                .clipShape(Circle())
                        }
                        // 前回位置(36, -10)を維持
                        .padding(.top, 36)
                        .padding(.trailing, -10)
                    }
                    Spacer()
                }
                .zIndex(5)
            }
        }
        // シート設定
        .sheet(isPresented: $isShowingExaminerSheet) {
            ExaminerMenuView()
        }
    }

    // MARK: - VAS値の保存
    func saveVAS(value: Double) {
        let rounded = Int(round(value))
        let now = Date()

        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        let ts = formatter.string(from: now)
        let modeString = isNonBiasMode ? "NonBiased" : "Standard"

        let row = "\(ts),\(rounded),\(modeString)\n"

        do {
            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let url = docs.appendingPathComponent("iphone15_vas.csv")

            let fm = FileManager.default

            if !fm.fileExists(atPath: url.path) {
                let header = "timestamp,vas_value,mode\n"
                let data = (header + row).data(using: .utf8)!
                try data.write(to: url, options: .atomic)
            } else {
                let handle = try FileHandle(forWritingTo: url)
                defer { try? handle.close() }
                try handle.seekToEnd()
                if let data = row.data(using: .utf8) {
                    try handle.write(contentsOf: data)
                }
            }
        } catch {
            print("VAS保存エラー:", error.localizedDescription)
        }
    }
}

// 検者用メニュー
struct ExaminerMenuView: View {
    @AppStorage("isNonBiasMode") private var isNonBiasMode: Bool = false

    private var csvURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("iphone15_vas.csv")
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("表示設定")) {
                    Toggle("ノンバイアスモード", isOn: $isNonBiasMode)
                    Text(isNonBiasMode ? "※ 三角形と青いバーのみ表示します" : "※ 絵文字と文字ラベルを表示します")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Section(header: Text("データ管理")) {
                    ShareLink(item: csvURL) {
                        Label("CSVをエクスポート", systemImage: "square.and.arrow.up")
                    }
                }
            }
            .navigationTitle("検者メニュー")
        }
    }
}
