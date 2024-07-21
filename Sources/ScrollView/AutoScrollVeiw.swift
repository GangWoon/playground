import SwiftUI

public struct AutoScrollView<Content: View, ID: Hashable>: View {
  var axis: Axis.Set
  var scrollID: ID?
  var contents: () -> Content
  
  @Environment(\.autoScrollAnchor) private var anchor
  
  public init(
    axis: Axis.Set = .vertical,
    scrollID: ID?,
    contents: @escaping () -> Content
  ) {
    self.axis = axis
    self.scrollID = scrollID
    self.contents = contents
  }
  
  public var body: some View {
    ScrollViewReader { proxy in
      ScrollView(axis) {
        contents()
      }
      .onChange(of: scrollID) {
        guard let id = $0 else { return }
        withAnimation {
          proxy.scrollTo(id, anchor: anchor)
        }
      }
    }
  }
}

extension View {
  public func autoScrollAnchor(_ anchor: UnitPoint?) -> some View {
    environment(\.autoScrollAnchor, anchor)
  }
}

struct AutoScrollAnchor: @preconcurrency EnvironmentKey {
  @MainActor static var defaultValue: UnitPoint? = nil
}

extension EnvironmentValues {
  var autoScrollAnchor: UnitPoint? {
    get { self[AutoScrollAnchor.self] }
    set { self[AutoScrollAnchor.self] = newValue }
  }
}

/// Example
///
///

@available(iOS 18.0, *)
#Preview {
  @Previewable @State var scrollID: Int?
  
  AutoScrollView(scrollID: scrollID) {
    ForEach(0..<100) { number in
      Text("item \(number)")
        .id(number)
        .padding()
        .onTapGesture {
          scrollID = number
        }
    }
  }
  .autoScrollAnchor(.top)
}
