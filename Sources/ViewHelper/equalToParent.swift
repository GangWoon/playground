import UIKit

extension UIView {
  public func equalToParent(
    useSafeArea: Bool = false,
    file: StaticString = #file,
    line: UInt = #line
  ) {
    guard let superview else {
      debugPrint("Error: No superview found in view hierarchy. Check \(file) at line \(line).")
      return
    }
    translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      topAnchor.constraint(
        equalTo: useSafeArea ? superview.safeAreaLayoutGuide.topAnchor : superview.topAnchor
      ),
      leadingAnchor.constraint(
        equalTo: useSafeArea ? superview.safeAreaLayoutGuide.leadingAnchor : superview.leadingAnchor
      ),
      trailingAnchor.constraint(
        equalTo: useSafeArea ? superview.safeAreaLayoutGuide.trailingAnchor : superview.trailingAnchor
      ),
      bottomAnchor.constraint(
        equalTo: useSafeArea ? superview.safeAreaLayoutGuide.bottomAnchor : superview.bottomAnchor
      )
    ])
  }
}
