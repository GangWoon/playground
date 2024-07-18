import SwiftUI

struct DigitSegmentGroupLayout: Layout {
  let layoutConfiguraitons: [LayoutConfiguration]
  struct LayoutConfiguration: Hashable {
    let xOffset: CGFloat
    let yOffset: CGFloat
    let rotation: Angle
  }
  
  init(_ layoutConfiguraitons: [LayoutConfiguration]) {
    self.layoutConfiguraitons = layoutConfiguraitons
  }
  
  func sizeThatFits(
    proposal: ProposedViewSize,
    subviews: Subviews,
    cache: inout ()
  ) -> CGSize {
    let width = proposal.width ?? .zero
    return CGSize(
      width: width,
      height: width * (2 * Ratio.width + Ratio.height)
    )
  }
  
  func placeSubviews(
    in bounds: CGRect,
    proposal: ProposedViewSize,
    subviews: Subviews,
    cache: inout ()
  ) {
    let segmentWidth = bounds.width * (Ratio.width - 2 * Ratio.spacing)
    let segmentHeight = bounds.width * Ratio.height
    
    let originX = bounds.minX + Ratio.spacing * bounds.width
    let originY = bounds.minY
    
    subviews.enumerated()
      .forEach { index, subview in
        let size = subview.sizeThatFits(proposal)
        let segment = layoutConfiguraitons[index]
        let point = CGPoint(
          x: size.width * segment.xOffset,
          y: size.width * segment.yOffset
        )
        subview.place(
          at: .init(x: originX + point.x, y: originY + point.y),
          proposal: .init(width: segmentWidth, height: segmentHeight)
        )
      }
  }
}

extension DigitSegmentGroupLayout {
  enum Ratio {
    static let width = 0.8
    static let height = 0.2
    static let spacing = 0.05
  }
}
