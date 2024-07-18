import SwiftUI

struct DigitView: View {
  var digit: Digit {
    .init(number)
  }
  var number: Int
  
  var segmentViewStates: [SegmentViewState] {
    zip(layoutConfigurations.map(\.rotation), digit.segmentStatus)
      .map(SegmentViewState.init)
  }
  struct SegmentViewState: Identifiable {
    let id: UUID = .init()
    var rotation: Angle
    var isActive: Bool
  }
  
  @Environment(\.layoutConfigurations) private var layoutConfigurations
  
  var body: some View {
    DigitSegmentGroupLayout(layoutConfigurations) {
      ForEach(segmentViewStates) { state in
        DigitSegment()
          .rotation(state.rotation)
          .fill(Color.neuBackground)
          .shadow(
            color: .dropShadow,
            radius: state.isActive ? 4 : -2,
            x: state.isActive ? 4 : 0,
            y: state.isActive ? 4 : 0
          )
          .shadow(
            color: .dropLight,
            radius: state.isActive ? -2 : 0,
            x: state.isActive ? -2 : 0,
            y: state.isActive ? -2 : 0
          )
          .animation(.easeInOut, value: digit)
      }
    }
  }
}
