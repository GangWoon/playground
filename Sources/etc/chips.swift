import SwiftUI

struct ChipLayout: Layout {
  let horizontalSpacing: CGFloat
  let verticalSpacing: CGFloat
  
  func sizeThatFits(
    proposal: ProposedViewSize,
    subviews: Subviews,
    cache: inout ()
  ) -> CGSize {
    var sumX: CGFloat = 0
    var sumY: CGFloat = 0
    var maxHeight: CGFloat = 0
    
    for view in subviews {
      guard let proposalWidth = proposal.width else { continue }
      let viewSize = view.sizeThatFits(.unspecified)
      
      if sumX + viewSize.width > proposalWidth {
        sumX = 0
        sumY += maxHeight + verticalSpacing
        maxHeight = 0
      }
      maxHeight = max(maxHeight, viewSize.height)
      sumX += viewSize.width + horizontalSpacing
    }
    sumY += maxHeight
    return CGSize(width: proposal.width ?? 0, height: sumY)
  }
  
  func placeSubviews(
    in bounds: CGRect,
    proposal: ProposedViewSize,
    subviews: Subviews,
    cache: inout ()
  ) {
    var sumX = bounds.minX
    var sumY = bounds.minY
    
    for view in subviews {
      guard let prposalWidth = proposal.width else { continue }
      let viewSize = view.sizeThatFits(.unspecified)
  
      if sumX + viewSize.width > prposalWidth {
        sumX = bounds.minX
        sumY += viewSize.height
        sumY += verticalSpacing
      }
      view.place(
        at: .init(x: sumX, y: sumY),
        anchor: .topLeading,
        proposal: proposal
      )
      sumX += (viewSize.width + horizontalSpacing)
    }
  }
}

#Preview {
  @Previewable @State var item = [
    "123",
    "123456",
    "abcdefg",
    "가나다라마바사",
    "안녕하세요",
    "1",
    "11234",
    "123 234"
  ]
  ScrollView {
    ChipLayout(
      horizontalSpacing: 8,
      verticalSpacing: 8
    ) {
      ForEach(item, id:\.self) {
        Text($0)
          .padding(.horizontal, 12)
          .padding(.vertical, 5)
          .background {
            Capsule().foregroundStyle(.indigo)
          }
      }
    }
    
    Color.yellow.frame(height: 300)
  }
}
