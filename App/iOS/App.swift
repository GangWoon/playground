import SwiftUI
import ScrollView

@main
struct playground: App {
  @State private var items: [Int] = [1, 2, 3]
  var body: some Scene {
    WindowGroup {
      InfiniteCarousel(items) { item in
        Text("\(item)")
          .frame(maxWidth: .infinity)
          .frame(height: 400)
          .background {
            if item == 1 {
              Color.red
            } else if item == 2 {
              Color.blue
            } else {
              Color.yellow
            }
          }
      }
    }
  }
}
