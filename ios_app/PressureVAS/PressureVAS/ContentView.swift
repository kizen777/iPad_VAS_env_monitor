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
    // VAS の物理幅（100mm 相当をあとで実測して調整）
    private let vasWidth: CGFloat = 520
    // 記録ボタンの物理幅（16cm 相当をあとで実測して調整）
    private let recordButtonWidth: CGFloat = 600

    // VAS 値を一時的に表示しているか
    @State private var isShowingValue: Bool = false
    // 記録中かどうか（ボタンの色・文言切り替え用）
    @State private var isRecording: Bool = false

    var body: some View {
        VStack {
            // 上のタイトル
            Text("今の痛みの強さを、\nスライダーを左右に動かして示してください。")
                .font(.title)
                .multilineTextAlignment(.center)
                .padding(.top, 40)

            Spacer()
                .frame(height: 40)

            // --- VAS ラインとガイド一式 ---
            VStack(spacing: 24) {

                // ① 上段：絵文字（両端のてっぺん付近）
                GeometryReader { geo in
                    let width = geo.size.width

                    ZStack {
                        // 左端のてっぺんの真上
                        Text("😀")
                            .font(.system(size: 60))
                            .position(x: 0, y: geo.size.height / 2)

                        // 右端のてっぺんの真上
                        Text("😫")
                            .font(.system(size: 60))
                            .position(x: width, y: geo.size.height / 2)
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
                            .font(.title2.bold())
                            .position(x: 0, y: geo.size.height / 1)

                        Text("耐えられないほど痛い")
                            .font(.title2.bold())
                            .position(x: width, y: geo.size.height / 1)
                    }
                }
                .frame(width: vasWidth, height: 40)
            }
            .padding()

            Spacer()

            // 記録ボタンのすぐ上に、10秒だけ VAS値を表示
            if isShowingValue {
                Text("\(Int(vasValue))")
                    .font(.system(size: 80, weight: .bold))
                    .padding(.bottom, 10)
            }

            // 記録ボタン
            Button {
                // 二重押し防止：すでに記録中なら何もしない
                guard !isRecording else { return }

                // 1. 状態を「記録中」にして値を表示
                isRecording = true
                isShowingValue = true

                // 2. 10秒後に記録＆ホームポジションへ戻す
                DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                    // ここで vasValue を保存（CSV/JSON など）する処理を書く
                    // 例: saveVAS(value: vasValue)

                    // 表示と記録中フラグをオフ
                    isShowingValue = false
                    isRecording = false

                    // スライダーをホームポジション 50 へ
                    vasValue = 50.0
                }
            } label: {
                Text(isRecording ? "記録しています…" : "記録")
                    .font(.system(size: 32, weight: .bold))
                    .padding(.vertical, 16)
                    .frame(width: recordButtonWidth)
                    .background(isRecording ? Color.white : Color.blue)      // 色反転
                    .foregroundColor(isRecording ? Color.blue : Color.white) // 色反転
                    .cornerRadius(12)
                    .padding(.bottom, 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}

#Preview {
    ContentView()
}
