import SwiftUI

struct HidableHeaderScrollView: View {
  @State private var isHeaderVisible: Bool = true
  @State private var turningPoint: CGFloat = .zero
  
  var scrollViewName: String = "SCROLLVIEW"
  
  var body: some View {
    VStack {
      if isHeaderVisible {
        Color.indigo
          .frame(height: 60)
          .overlay {
            Text("Header")
              .font(.title)
          }
          .transition(
              .asymmetric(
                  insertion: .push(from: .top),
                  removal: .push(from: .bottom)
              )
          )
      }
      
      GeometryReader { outer in
        ScrollView {
          VStack {
            ForEach(0..<100, id: \.self) { _ in
              Color.random()
                .frame(maxWidth: .infinity)
                .frame(height: Bool.random() ? 100 : 200)
                .background(Color.orange)
            }
          }
          .background {
            GeometryReader { proxy in
              let contentHeight = proxy.size.height
              let minY = max(
                min(0, proxy.frame(in: .named(scrollViewName)).minY),
                outer.size.height - contentHeight
              )
              Color.clear
                .onChange(of: minY) { oldValue, newValue in
                  let threshold = 50.0
                  if
                    isHeaderVisible && newValue > oldValue
                    || !isHeaderVisible && newValue < oldValue
                  {
                    turningPoint = newValue
                  }
                  
                  let headerHeight = 50.0
                  if
                    isHeaderVisible && turningPoint > newValue
                    || !isHeaderVisible && (newValue - turningPoint - headerHeight) > threshold
                  {
                    isHeaderVisible = newValue > turningPoint
                  }
                }
            }
          }
        }
        .coordinateSpace(.named(scrollViewName))
      }
      .padding(.top, 1)
    }
    .animation(.easeInOut, value: isHeaderVisible)
  }
}

#Preview {
  HidableHeaderScrollView()
}

extension Color {
    static func random() -> Color {
        return Color(
            red: Double.random(in: 0...1),
            green: Double.random(in: 0...1),
            blue: Double.random(in: 0...1)
        )
    }
}
