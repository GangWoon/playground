import Foundation

enum Digit: CaseIterable {
  var segmentStatus: [Bool] {
    switch self {
    case .zero:
      return [true, true, true, false, true, true, true]
    case .one:
      return [false, false, true, false, false, true, false]
    case .two:
      return [true, false, true, true, true, false, true]
    case .three:
      return [true, false, true, true, false, true, true]
    case .four:
      return [false, true, true, true, false, true, false]
    case .five:
      return [true, true, false, true, false, true, true]
    case .six:
      return [true, true, false, true, true, true, true]
    case .seven:
      return [true, false, true, false, false, true, false]
    case .eight:
      return [true, true, true, true, true, true, true]
    case .nine:
      return [true, true, true, true, false, true, true]
    }
  }
  case zero, one, two, three, four, five, six, seven, eight, nine
  
  init(_ number: Int) {
    switch number {
    case 0:
      self = .zero
    case 1:
      self = .one
    case 2:
      self = .two
    case 3:
      self = .three
    case 4:
      self = .four
    case 5:
      self = .five
    case 6:
      self = .six
    case 7:
      self = .seven
    case 8:
      self = .eight
    case 9:
      self = .nine
    default:
      self = .zero
    }
  }
}
