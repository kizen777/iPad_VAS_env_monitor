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
    
    // 患者ID
    @AppStorage("patientID") private var patientID: String = ""
    @State private var tempPatientID: String = ""   // ← 後で不要になるが今はそのまま
    
    // 患者IDカウンター（次に使う番号）
    @AppStorage("nextPatientNumber") private var nextPatientNumber: Int = 1
    
    // 患者基本情報（改良版）
    @AppStorage("patientLastName") private var lastName: String = ""    // 姓
    @AppStorage("patientFirstName") private var firstName: String = ""  // 名
    @AppStorage("patientBirthDate") private var birthDate: Date = Date()
    @AppStorage("patientGender") private var gender: String = "M"
    @AppStorage("patientHeight") private var height: Double = 170.0
    @AppStorage("patientWeight") private var weight: Double = 60.0
    
    // 一時入力用
    @State private var tempLastName: String = ""
    @State private var tempFirstName: String = ""
    @State private var tempBirthDate: Date = Date()
    @State private var tempGender: String = "M"
    @State private var tempHeight: Double = 170.0
    @State private var tempWeight: Double = 60.0
    
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

    // BMI 計算
    private func calculateBMI(height: Double, weight: Double) -> Double {
        let heightM = height / 100.0
        guard heightM > 0 else { return 0 }
        return weight / (heightM * heightM)
    }
    
    // 年齢計算
    private func calculateAge(from birthDate: Date) -> Int {
        let calendar = Calendar.current
        let now = Date()
        let comps = calendar.dateComponents([.year], from: birthDate, to: now)
        return comps.year ?? 0
    }
    
    // MARK: - 画面本体
    var body: some View {
        // 患者ID未登録なら登録画面
        if patientID.isEmpty {
            VStack(spacing: 16) {
                Text("患者情報を登録してください")
                    .font(.title2)
                    .padding(.top, 32)
                
                // 患者ID
                TextField("患者ID（例: 001）", text: $tempPatientID)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                
                // 姓・名
                HStack {
                    TextField("姓（例: 山田）", text: $tempLastName)
                        .textFieldStyle(.roundedBorder)
                    TextField("名（例: たか）", text: $tempFirstName)
                        .textFieldStyle(.roundedBorder)
                }
                .padding(.horizontal)
                
                // 生年月日
                DatePicker("生年月日", selection: $tempBirthDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .padding(.horizontal)
                
                // 性別
                Picker("性別", selection: $tempGender) {
                    Text("男性").tag("M")
                    Text("女性").tag("F")
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // 身長・体重
                HStack {
                    TextField("身長(cm)", value: $tempHeight, format: .number)
                        .textFieldStyle(.roundedBorder)
                    TextField("体重(kg)", value: $tempWeight, format: .number)
                        .textFieldStyle(.roundedBorder)
                }
                .padding(.horizontal)
                
                // BMI 表示
                Text("BMI: \(String(format: "%.1f", calculateBMI(height: tempHeight, weight: tempWeight)))")
                    .font(.headline)
                    .foregroundColor(.blue)
                
                // 登録ボタン
                Button("登録する") {
                    // 自動採番: 1 → "001", 2 → "002" ...
                    let generatedID = String(format: "%03d", nextPatientNumber)

                    // ここで generatedID を使う
                    patientID = generatedID
                    lastName = tempLastName
                    firstName = tempFirstName
                    birthDate = tempBirthDate
                    gender = tempGender
                    height = tempHeight
                    weight = tempWeight

                    // 次の患者用に番号を+1
                    nextPatientNumber += 1
                }

                .buttonStyle(.borderedProminent)
                .disabled(
                    tempPatientID.trimmingCharacters(in: .whitespaces).isEmpty ||
                    tempLastName.trimmingCharacters(in: .whitespaces).isEmpty ||
                    tempFirstName.trimmingCharacters(in: .whitespaces).isEmpty
                )
                .padding(.vertical, 24)
            }
        } else {            // 既存の VAS 画面（GeometryReader { geo in ... }）はそのまま
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
                        Text("今の痛み『ここ』と思う位置まで，画面をタッチしながら\n青棒を横に動かして")
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
        
        // ★ ここで年齢とBMIを計算する
        let age = calculateAge(from: birthDate)
        let bmi = calculateBMI(height: height, weight: weight)
        
        // ★ CSV 1行分（列を増やした版）
        let row = "\(ts)," +
                  "\(patientID)," +
                  "\(lastName)," +
                  "\(firstName)," +
                  "\(age)," +
                  "\(gender)," +
                  "\(Int(height))," +
                  "\(Int(weight))," +
                  "\(String(format: "%.1f", bmi))," +
                  "\(rounded)," +
                  "\(modeString)\n"
        
        do {
            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let url = docs.appendingPathComponent("iphone15_vas.csv")
            
            let fm = FileManager.default
            
            if !fm.fileExists(atPath: url.path) {
                // ★ ヘッダーも列を揃える
                let header = "timestamp,patient_id,last_name,first_name,age,gender,height_cm,weight_kg,bmi,vas_value,mode\n"
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

    // 患者情報（読み取り用）
    @AppStorage("patientID") private var patientID: String = ""
    @AppStorage("patientLastName") private var lastName: String = ""
    @AppStorage("patientFirstName") private var firstName: String = ""
    @AppStorage("patientBirthDate") private var birthDate: Date = Date()
    @AppStorage("patientGender") private var gender: String = "M"
    @AppStorage("patientHeight") private var height: Double = 170.0
    @AppStorage("patientWeight") private var weight: Double = 60.0

    private var csvURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("iphone15_vas.csv")
    }
    
    // 年齢計算
    private func calculateAge(from birthDate: Date) -> Int {
        let calendar = Calendar.current
        let now = Date()
        let comps = calendar.dateComponents([.year], from: birthDate, to: now)
        return comps.year ?? 0
    }

    // BMI計算（ContentViewと同じ式）
    private func calculateBMI(height: Double, weight: Double) -> Double {
        let heightM = height / 100.0
        guard heightM > 0 else { return 0 }
        return weight / (heightM * heightM)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("患者情報")) {
                    if patientID.isEmpty {
                        Text("患者情報は未登録です")
                            .foregroundColor(.secondary)
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("ID:")
                                    .bold()
                                Text(patientID)
                                Text("氏名:")
                                    .bold()
                                Text("\(lastName) \(firstName)")
                            }
                            HStack {
                                Text("生年月日:")
                                    .bold()
                                Text(birthDate, style: .date)   // 例: 1965/04/01
                                Text("年齢:")
                                    .bold()
                                Text("\(calculateAge(from: birthDate)) 歳")
                            }
                            HStack {
                                Text("性別:")
                                    .bold()
                                Text(gender == "M" ? "男性" : "女性")
                                Text("身長:")
                                    .bold()
                                Text("\(Int(height)) cm")
                            }
                            HStack {
                                Text("体重:")
                                    .bold()
                                Text("\(Int(weight)) kg")
                                Text("BMI:")
                                    .bold()
                                Text(String(format: "%.1f", calculateBMI(height: height, weight: weight)))
                                    .foregroundColor(.blue)
                            }
                        }

                        Button("患者情報を変更") {
                            patientID = ""
                        }
                        .foregroundStyle(.red)
                    }
                }

                
                Section(header: Text("データ管理")) {
                    Button("CSVをエクスポート") {
                        // 既存のCSVエクスポートコード
                    }
                }
            }
            .navigationTitle("検者メニュー")
        }
    }
}

