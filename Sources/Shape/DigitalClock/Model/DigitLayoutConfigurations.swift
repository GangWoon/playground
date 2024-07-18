import struct SwiftUI.EnvironmentValues
import protocol SwiftUI.EnvironmentKey

struct DigitLayoutConfigurationsKey : EnvironmentKey {
  static let defaultValue: [DigitSegmentGroupLayout.LayoutConfiguration] = [
    .init(
      xOffset: DigitSegmentGroupLayout.Ratio.height * 0.5,
      yOffset: .zero,
      rotation: .zero
    ),
    .init(
      xOffset: -DigitSegmentGroupLayout.Ratio.height * 1.5,
      yOffset: DigitSegmentGroupLayout.Ratio.width * 0.5,
      rotation: .degrees(90)
    ),
    .init(
      xOffset: 0.5,
      yOffset: DigitSegmentGroupLayout.Ratio.width * 0.5,
      rotation: .degrees(90)
    ),
    .init(
      xOffset: DigitSegmentGroupLayout.Ratio.height * 0.5,
      yOffset: DigitSegmentGroupLayout.Ratio.width,
      rotation: .zero
    ),
    .init(
      xOffset: -DigitSegmentGroupLayout.Ratio.height * 1.5,
      yOffset: DigitSegmentGroupLayout.Ratio.width + (2 * DigitSegmentGroupLayout.Ratio.height),
      rotation: .degrees(90)
    ),
    .init(
      xOffset: 0.5,
      yOffset: DigitSegmentGroupLayout.Ratio.width + 2 * DigitSegmentGroupLayout.Ratio.height,
      rotation: .degrees(90)
    ),
    .init(
      xOffset: DigitSegmentGroupLayout.Ratio.height * 0.5,
      yOffset: DigitSegmentGroupLayout.Ratio.width * 2,
      rotation: .zero
    )
  ]
}

extension EnvironmentValues {
  var layoutConfigurations: [DigitSegmentGroupLayout.LayoutConfiguration] {
    get { self[DigitLayoutConfigurationsKey.self] }
  }
}
