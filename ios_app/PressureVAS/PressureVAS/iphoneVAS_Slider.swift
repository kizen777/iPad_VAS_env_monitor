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
    // 表示設定
    @AppStorage("isNonBiasMode") private var isNonBiasMode: Bool = false
    
    // 患者 ID 登録
    @AppStorage("patientID") private var patientID: String = ""
    @State private var tempPatientID: String = ""
    
    // VAS関連状態
    @State private var vasValue: Double = 50.0
    @State private var isShowingValue: Bool = false
    @State private var isRecording: Bool = false
    @State private var isShowingExaminerSheet: Bool = false
    
    // 端末ごとのVAS幅
    private var vasWidth: CGFloat {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return 600   // iPad
        } else {
            return 530   // iPhone 15 Pro Max 相当
        }
    }
    
    private let triangleHeight: CGFloat = 175
    private let darkSignatureBlue = Color(red: 0.0, green: 0.0, blue: 0.4)
    
    var isPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }
    
    // MARK: - 画面本体
    var body: some View {
        // 患者ID未登録なら登録画面
        if patientID.isEmpty {
            VStack {
                Text("患者IDを登録してください")
                    .font(.title)
                    .padding()
                TextField("患者ID（例: P001）", text: $tempPatientID)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                Button("登録する") {
                    patientID = tempPatientID
                }
                .disabled(tempPatientID.isEmpty)
            }
            .padding()
        } else {
            // VAS画面
            GeometryReader { geo in
                ZStack {
                    // レイヤー0：隠し署名
                    Text("Kizen Sasaki")
                        .font(.custom("Zapfino", size: 7))
                        .foregroundColor(darkSignatureBlue)
                        .position(x: geo.size.width / 2, y: geo.size.height + 7)
                        .zIndex(0)
                    
                    // レイヤー1：タイトル
                    VStack {
                        Text("今の痛みの強さをスライダーを示してください")
                            .font(.title)
                            .multilineTextAlignment(.center)
                            .padding(.top, 31)
                        Spacer()
                    }
                    .zIndex(1)
                    
                    // レイヤー2：VASスライダー
                    VStack(spacing: 0) {
                        // 上段：絵文字
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
                        
                        // 三角定規＋ガイド
                        ZStack {
                            TriangularVASBar()
                                .fill(Color.blue.opacity(0.3))
                            
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
                        
                        // 下段：ラベル
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
                    .position(x: geo.size.width / 2, y: geo.size.height / 2 + 3)
                    .zIndex(2)
                    
                    // レイヤー3：VAS数値の表示
                    if isShowingValue {
                        Text("\(Int(vasValue))")
                            .font(.system(size: 80, weight: .bold))
                            .padding(10)
                            .background(Color.white.opacity(0.6))
                            .cornerRadius(10)
                            .position(x: geo.size.width / 2, y: geo.size.height - 190)
                            .zIndex(3)
                    }
                    
                    // レイヤー4：記録ボタン
                    Button {
                        guard !isRecording else { return }
                        isRecording = true
                        isShowingValue = true
                        
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
                    .position(x: geo.size.width / 2, y: geo.size.height - 35)
                    .zIndex(4)
                    
                    // レイヤー5：検者ボタン
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
                            .padding(.top, 36)
                            .padding(.trailing, -10)
                        }
                        Spacer()
                    }
                    .zIndex(5)
                }
            }
            .sheet(isPresented: $isShowingExaminerSheet) {
                ExaminerMenuView()
            }
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
        
        let row = "\(ts),\(patientID),\(rounded),\(modeString)\n"
        
        do {
            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let url = docs.appendingPathComponent("iphone15_vas.csv")
            
            let fm = FileManager.default
            
            if !fm.fileExists(atPath: url.path) {
                let header = "timestamp,patient_id,vas_value,mode\n"
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
    @AppStorage("patientID") private var patientID: String = ""
    
    private var csvURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("iphone15_vas.csv")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("表示設定")) {
                    Toggle("ノンバイアスモード", isOn: $isNonBiasMode)
                    Text(isNonBiasMode ? "※ 三角形と青いバーのみ表示します" :
                         "※ 絵文字と文字ラベルを表示します")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Section(header: Text("データ管理")) {
                    ShareLink(item: csvURL) {
                        Label("CSVをエクスポート", systemImage: "square.and.arrow.up")
                    }
                }
                
                // ★ ここから追加：患者IDの確認表示 ★
                Section(header: Text("患者ID")) {
                    Text("現在の患者ID: \(patientID.isEmpty ? "未登録" : patientID)")
                        .font(.body)
                }
                // ★ 追加ここまで ★
            }
            .navigationTitle("検者メニュー")
        }
    }
}
