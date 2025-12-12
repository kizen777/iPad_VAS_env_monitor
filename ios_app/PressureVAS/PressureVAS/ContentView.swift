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
    // スライダー位置（0.0〜100.0）
    @State private var vasValue: Double = 50.0
    // 記録ボタンの物理幅（16cm 相当をあとで実測して調整）
    private let recordButtonWidth: CGFloat = 600
    
    // 端末ごとに長さを変える VAS 幅
    private var vasWidth: CGFloat {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return 600   // iPadで実測して100mm±2mmだった値
        } else {
            return 560   // iPhone 15 Pro Maxで実測して100mm±2mmだった値
        }
    }
    
    private let twoCmInPoints: CGFloat = 60
    
    var isPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }
    
    
    // VAS 値を一時的に表示しているか
    @State private var isShowingValue: Bool = false
    // 記録中かどうか（ボタンの色・文言切り替え用）
    @State private var isRecording: Bool = false
    
    var body: some View {
        VStack {
            // 上のタイトル
            Text("今の痛みの強さをスライダーを示してください")
                .font(.title)
                .multilineTextAlignment(.center)
                .padding(.top, 100)
            
            Spacer()
                .frame(height: 0)
            
            // --- VAS ラインとガイド一式 ---
            VStack(spacing: 24) {
                
                // ① 上段：絵文字（両端のてっぺん付近）
                GeometryReader { geo in
                    let width = geo.size.width
                    
                    ZStack {
                        // 左端のてっぺんの真上
                        Text("😀")
                            .font(.system(size: 60))
                            .position(x: 0,
                                      y: geo.size.height - 15)  // ← 同じくここ
                        
                        // 右端のてっぺんの真上
                        Text("😫")
                            .font(.system(size: 60))
                            .position(x: width,
                                      y: geo.size.height - 15)  // ← 同じくここ
                    }
                }
                .frame(width: vasWidth, height: 80)
                
                // ② 三角定規＋ガイド
                ZStack {
                    TriangularVASBar()
                        .fill(Color.blue.opacity(0.3))
                    
                    GeometryReader { geo in
                        let width = geo.size.width
                        let xPos = CGFloat(vasValue / 100.0) * width
                        
                        Rectangle()
                            .fill(Color.blue)
                            .frame(width: 4, height: geo.size.height+50)
                            .position(x: xPos, y: geo.size.height / 2)
                    }
                }
                .frame(width: vasWidth, height: 80)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let width = vasWidth
                            let clampedX = min(max(0, value.location.x), width)
                            vasValue = Double(clampedX / width) * 100.0
                        }
                )
                
                // ③ 下段：文字ラベル（両端のてっぺんの真下付近）
                GeometryReader { geo in
                    let width = geo.size.width
                    
                    ZStack {
                        Text("全く痛くない")
                            .font(.system(size: isPhone ? 20 : 28, weight: .bold))
                            .position(x: 0,
                                      y: geo.size.height - 30)  // ← ここを調整（-20 ≒ 約5mmぶん）
                        
                        Text("耐えられないほど痛い")
                            .font(.system(size: isPhone ? 20 : 28, weight: .bold))
                            .position(x: width,
                                      y: geo.size.height - 30)  // ← 同じくここ
                    }
                }
                .frame(width: vasWidth, height: 40)
            }
            .padding()
            .padding(.top, -30) // ここを追加(約5mm分底上げかな）
            
            Spacer()
            
            // 記録ボタンのすぐ上に、10秒だけ VAS値を表示
            if isShowingValue {
                Text("\(Int(vasValue))")
                    .font(.system(size: 80, weight: .bold))
                    .padding(.bottom, twoCmInPoints)
            }
            
            // 記録ボタン
            GeometryReader { geo in
                // 片側 25〜30mm にしたいので、まず 150pt 前後からスタート
                let marginPerSide: CGFloat = 260  // 実機で25〜30mmになるよう微調整

                Button {
                    guard !isRecording else { return }

                    isRecording = true
                    isShowingValue = true

                    DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                        // saveVAS(value: vasValue)
                        isShowingValue = false
                        isRecording = false
                        vasValue = 50.0
                    }
                } label: {
                    Text(isRecording ? "記録しています…" : "記録")
                        .font(.system(size: 32, weight: .bold))
                        .padding(.vertical, 10) // 記録ボタンの厚み
                        .frame(
                            width: geo.size.width - marginPerSide * 2
                        )
                        .background(isRecording ? Color.white : Color.blue)
                        .foregroundColor(isRecording ? Color.blue : Color.white)
                        .cornerRadius(12)
                }
                // ここで GeometryReader 内の横方向をセンターに配置
                .padding(.top, -20)  // 全体を約5mmぶん上に
                .frame(maxWidth: .infinity, alignment: .center)
              //  .padding(.bottom, twoCmInPoints + 10) // 最底部よりの余白
            }
            .frame(height: 100)
        }
    }
}
