import SwiftUI

struct EdgeCorners: Shape {
  var animatableData: CGFloat {
    get { progress }
    set { progress = newValue }
  }
  var progress: CGFloat
  
  var isSelected: Bool
  
  init(isSelected: Bool) {
    self.isSelected = isSelected
    self.progress = isSelected ? 1 : 0
  }
  
  func path(in rect: CGRect) -> Path {
    var path = Path()
    path.addPath(cornerPath(in: rect))
    path.addPath(
      cornerPath(in: rect)
        .applying(CGAffineTransform(rotationAngle: .pi / 2))
        .applying(CGAffineTransform(translationX: rect.width, y: 0))
    )
    path.addPath(
      cornerPath(in: rect)
        .applying(CGAffineTransform(rotationAngle: .pi))
        .applying(CGAffineTransform(translationX: rect.width, y: rect.height))
    )
    path.addPath(
      cornerPath(in: rect)
        .applying(CGAffineTransform(rotationAngle: 3 * .pi / 2))
        .applying(CGAffineTransform(translationX: 0, y: rect.height))
    )
    
    return path
  }
  
  private func cornerPath(in rect: CGRect) -> Path {
    let width = rect.width * 0.4
    let height = rect.height * 0.4
    
    var path = Path()
    path.move(to: CGPoint(x: 0, y: height))
    path.addLine(
      to: CGPoint(
        x: progress * width,
        y: progress * height
      )
    )
    path.addLine(to: CGPoint(x: width, y: 0))
    
    return path
  }
}

public struct FrameToCrossView: View {
  var isSelected: Bool
  var color: Color
  var lineWidth: CGFloat
  
  public init(
    isSelected: Bool,
    color: Color = .black,
    lineWidth: CGFloat = 2
  ) {
    self.isSelected = isSelected
    self.color = color
    self.lineWidth = lineWidth
  }
  
  public var body: some View {
    EdgeCorners(isSelected: isSelected)
      .stroke(color, lineWidth: lineWidth)
      .background(Color.clear)
      .contentShape(Rectangle())
      .animation(.easeInOut, value: isSelected)
  }
}

#Preview {
  @Previewable @State var isSelected: Bool = false
  
  VStack {
    FrameToCrossView(isSelected: isSelected)
      .onTapGesture { isSelected.toggle() }
      .frame(width: 50, height: 50)
  }
}
