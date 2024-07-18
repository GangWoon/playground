import SwiftUI

struct ScaleButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
      .animation(
        .spring(response: 0.7, dampingFraction: 0.8),
        value: configuration.isPressed
      )
  }
}

public struct ColorListView: View {
  var isDetailVisible: Bool {
    selectedColorItem != nil
  }
  @State private var selectedColorItem: ColorItem?
  
  private let colorList: [ColorItem] = .preview
  @Namespace var animation
  public init() {
    
  }
  public var body: some View {
    ScrollView {
      VStack {
        ForEach(colorList) { colorItem in
          Button(
            action: {
              withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) {
                selectedColorItem = colorItem
              }
            }
          ) {
            ColorView(
              colorItem: colorItem,
              namespaceID: animation
            )
            .frame(height: 250)
            .padding(.horizontal, 16)
            .shadow(radius: Dimens.unit16)
          }
          .buttonStyle(ScaleButtonStyle())
        }
      }
    }
    .scrollIndicators(.hidden)
    .opacity(selectedColorItem != nil ? 0 : 1)
    .overlay {
      if let selectedColorItem {
        DetailColorView(
          isShowing: .init(
            get: { isDetailVisible },
            set: { _ in self.selectedColorItem = nil }
          ),
          colorItem: selectedColorItem,
          namespaceID: animation
        )
      }
    }
  }
}

struct ColorView: View {
  var colorItem: ColorItem
  var namespaceID: Namespace.ID
  
  var body: some View {
    VStack {
      colorItem.color
        .matchedGeometryEffect(id: colorItem.color, in: namespaceID)
      
      HStack {
        Image(systemName: "pencil.tip.crop.circle")
        
        Text(colorItem.colorName)
        
        Spacer()
        
        Text("hex code: ").bold() + Text(colorItem.hexColor)
      }
      .padding()
      .matchedGeometryEffect(id: colorItem.hexColor, in: namespaceID)
    }
    .background {
      Color.white
        .matchedGeometryEffect(id: colorItem.roundColor, in: namespaceID)
    }
    .clipShape(RoundedRectangle(cornerRadius: 16))
    .overlay {
      RoundedRectangle(cornerRadius: 16)
        .stroke(Color(hex: colorItem.roundColor), lineWidth: 2)
    }
  }
}

struct DetailColorView: View {
  @Binding var isShowing: Bool
  var colorItem: ColorItem
  var namespaceID: Namespace.ID
  
  @State private var scaleFactor: CGFloat = 1
  @State private var isTextVisible: Bool = true
  
  var body: some View {
    ScrollView {
      VStack {
        colorItem.color
          .frame(height: 300)
          .matchedGeometryEffect(id: colorItem.color, in: namespaceID)
        
        HStack {
          Image(systemName: "pencil.tip.crop.circle")
          
          Text(colorItem.colorName)
          
          Spacer()
          
          Text("hex code: ").bold() + Text(colorItem.hexColor)
        }
        .padding()
        .matchedGeometryEffect(id: colorItem.hexColor, in: namespaceID)
        
        Text(colorItem.description)
          .padding(.horizontal)
        
        Spacer().frame(height: 300)
        
        Button(action: {
          withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) {
            self.isShowing = false
          }
        }) {
          Text("Tap")
        }
      }
      .scaleEffect(.init(width: scaleFactor, height: scaleFactor))
      .readVerticalScrollOffset {
        handleScrollEvent(offsetY: $0)
      }
    }
    .scrollIndicators(.hidden)
    .animation(.easeInOut, value: scaleFactor)
    .ignoresSafeArea(.all, edges: [.top])
    .background {
      Color.white
        .matchedGeometryEffect(id: colorItem.roundColor, in: namespaceID)
    }
  }
  
  func handleScrollEvent(offsetY: CGFloat) {
    guard offsetY < 0 else { return }
    let originalScale: CGFloat = 1.0
    let minScale: CGFloat = 0.85
    let dismissThreshold: CGFloat = -100.0
    
    if offsetY > dismissThreshold {
      scaleFactor = originalScale + (minScale - originalScale) * (offsetY / dismissThreshold)
    } else if offsetY <= dismissThreshold {
      withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) {
        isShowing.toggle()
      }
    }
  }
}

#Preview {
  ColorListView()
}

extension View {
  func readVerticalScrollOffset(_ closure: @escaping (CGFloat) -> Void) -> some View {
    self
      .background {
        GeometryReader { proxy in
          Color.clear
            .preference(
              key: VerticalScrollOffsetKey.self,
              value: -proxy.frame(in: .global).minY
            )
        }
      }
      .onPreferenceChange(VerticalScrollOffsetKey.self) {
        closure($0)
      }
  }
}

struct VerticalScrollOffsetKey: @preconcurrency PreferenceKey {
  @MainActor static var defaultValue: CGFloat = .zero
  
  static func reduce(
    value: inout CGFloat,
    nextValue: () -> CGFloat
  ) {
  }
}

extension Color {
  init(hex: String) {
    let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    var int: UInt64 = 0
    Scanner(string: hex).scanHexInt64(&int)
    let a, r, g, b: UInt64
    switch hex.count {
    case 3:
      (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
    case 6:
      (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
    case 8:
      (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
    default:
      (a, r, g, b) = (255, 0, 0, 0)
    }
    self.init(
      .sRGB,
      red: Double(r) / 255,
      green: Double(g) / 255,
      blue: Double(b) / 255,
      opacity: Double(a) / 255
    )
  }
}
