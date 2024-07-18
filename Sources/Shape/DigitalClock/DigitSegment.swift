import SwiftUI

struct DigitSegment: Shape {
  func path(in rect: CGRect) -> Path {
    let width = rect.size.width
    let height = rect.size.height
    let heightCenter = height * 0.5
    return Path { path in
      path.move(to: CGPoint(x: .zero, y: heightCenter))
      path.addLine(to: CGPoint(x: heightCenter, y: .zero))
      path.addLine(to: CGPoint(x: width - heightCenter, y: .zero))
      path.addLine(to: CGPoint(x: width, y: heightCenter))
      path.addLine(to: CGPoint(x: width - heightCenter, y: height))
      path.addLine(to: CGPoint(x: heightCenter, y: height))
      path.closeSubpath()
    }
  }
}
