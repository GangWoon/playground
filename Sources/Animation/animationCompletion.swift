import SwiftUI

public func withAnimationCompletion<Result>(
  _ animationWrapper: AnimationWrapper?,
  _ body: @escaping () throws -> Result,
  _ completion: @escaping @Sendable () -> Void
) rethrows -> Result {
  let result = try withAnimation(animationWrapper?.animation, body)
  let duration = animationWrapper?.duration ?? 0.35
  
  Task {
    try await Task.sleep(for: .seconds(duration))
    completion()
  }
  return result
}

public struct AnimationWrapper: Sendable {
  let animation: Animation
  let duration: Double
  
  public static func easeInOut(duration: Double) -> AnimationWrapper {
    return AnimationWrapper(animation: .easeInOut(duration: duration), duration: duration)
  }
  
  public static func easeIn(duration: Double) -> AnimationWrapper {
    return AnimationWrapper(animation: .easeIn(duration: duration), duration: duration)
  }
  
  public static func easeOut(duration: Double) -> AnimationWrapper {
    return AnimationWrapper(animation: .easeOut(duration: duration), duration: duration)
  }
  
  public static func linear(duration: Double) -> AnimationWrapper {
    return AnimationWrapper(animation: .linear(duration: duration), duration: duration)
  }
  
  public static func spring(
    response: Double = 0.5,
    dampingFraction: Double = 0.825,
    blendDuration: TimeInterval = 0
  ) -> AnimationWrapper {
    let estimatedDuration = response + blendDuration
    return AnimationWrapper(animation: .spring(response: response, dampingFraction: dampingFraction, blendDuration: blendDuration), duration: estimatedDuration)
  }
  
  public static let hero = Self.spring(response: 0.7)
}
