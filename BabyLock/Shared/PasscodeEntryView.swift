import SwiftUI

struct PasscodeEntryView: View {
    let title: String
    let onComplete: (String) -> Bool

    @State private var digits: String = ""
    @State private var shakeWrong = false
    @FocusState private var isFocused: Bool

    private let codeLength = 4

    var body: some View {
        VStack(spacing: 32) {
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)

            HStack(spacing: 16) {
                ForEach(0..<codeLength, id: \.self) { index in
                    Circle()
                        .fill(index < digits.count ? Color.primary : Color.clear)
                        .frame(width: 20, height: 20)
                        .overlay(
                            Circle().stroke(Color.primary, lineWidth: 2)
                        )
                }
            }
            .modifier(ShakeEffect(shakes: shakeWrong ? 4 : 0))

            TextField("", text: $digits)
                .keyboardType(.numberPad)
                .focused($isFocused)
                .frame(width: 0, height: 0)
                .opacity(0)
                .onChange(of: digits) { _, newValue in
                    let filtered = newValue.filter(\.isNumber)
                    if filtered != newValue {
                        digits = filtered
                    }
                    if filtered.count > codeLength {
                        digits = String(filtered.prefix(codeLength))
                    }
                    if digits.count == codeLength {
                        let accepted = onComplete(digits)
                        if !accepted {
                            withAnimation(.default) { shakeWrong = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                shakeWrong = false
                                digits = ""
                            }
                        }
                    }
                }
        }
        .onAppear { isFocused = true }
        .onTapGesture { isFocused = true }
    }
}

struct ShakeEffect: GeometryEffect {
    var shakes: Int
    var animatableData: CGFloat {
        get { CGFloat(shakes) }
        set { shakes = Int(newValue) }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        let offset = sin(animatableData * .pi * 2) * 10
        return ProjectionTransform(CGAffineTransform(translationX: offset, y: 0))
    }
}
