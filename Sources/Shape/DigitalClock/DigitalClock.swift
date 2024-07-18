import SwiftUI

extension Color {
  static let neuBackground = Color(red: 240 / 255, green: 240 / 255, blue: 243 / 255)
  static let dropShadow = Color(red: 174 / 255, green: 174 / 255, blue: 192 / 255, opacity: 0.4)
  static let dropLight = Color.white
}

struct DigitalClock: View {
  @State private var seconds: Double = 0
  
  var body: some View {
    VStack {
      HStack {
        DigitView(number: Int(seconds) / 1000 % 10)
        DigitView(number: Int(seconds) / 100 % 10)
        divider
        DigitView(number: Int(seconds) / 10 % 10)
        DigitView(number: Int(seconds) % 10)
      }
      .frame(height: 200)
    }
    .frame(maxHeight: .infinity)
    .ignoresSafeArea(.all)
    .background {
      Color.neuBackground.opacity(0.7)
    }
    .task {
      do {
        while seconds < 100000 {
          let second = Double.random(in: 0...300)
          seconds += second
          try await Task.sleep(for: .seconds(Double.random(in: 0.07...0.25)))
        }
      } catch { }
    }
  }
  
  private var divider: some View {
    VStack(alignment: .center) {
      applyNeumorphism(Circle())
        .frame(height: 20)
      applyNeumorphism(Circle())
        .frame(height: 20)
    }
  }
  
  private func applyNeumorphism(_ view: some Shape) -> some View {
    view
      .fill(Color.neuBackground)
      .shadow(
        color: .dropShadow,
        radius: 4,
        x: 4,
        y: 4
      )
      .shadow(
        color: .dropLight,
        radius: -2,
        x: -2,
        y: -2
      )
  }
}

#Preview {
  DigitalClock()
}
