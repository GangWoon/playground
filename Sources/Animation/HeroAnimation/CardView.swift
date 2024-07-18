import SwiftUI

#Preview {
  CardPreview()
}
struct CardPreview: View {
  @State private var isShowingDetail: Bool = false
  @State private var isAppeared: Bool = false
  @State private var isAnimating: Bool = false
  @State private var scaleFactor: CGFloat = 1
  @Namespace var animation
  
  var body: some View {
    ZStack {
      if isShowingDetail {
        CardDetail(
          isShowingDetail: $isShowingDetail,
          isAppeard: $isAppeared,
          animation: animation,
          scaleFactor: $scaleFactor
        )
        .scaleEffect(.init(width: scaleFactor, height: scaleFactor))
      } else {
        Card(
          isShowingDetail: $isShowingDetail,
          isAppeared: $isAppeared,
          animation: animation
        )
        .transition(.scale(scale: 1))
        .disabled(isAnimating)
      }
    }
    .onChange(of: isShowingDetail) { oldValue, newValue in
      checkOnGoingAnimation(newValue: newValue)
      scaleFactor = 1
    }
  }
  
  private func checkOnGoingAnimation(newValue: Bool) {
    if newValue {
      isAnimating = true
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
        isAnimating = false
      }
    } else {
      isAnimating = true
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
        isAnimating = false
      }
    }
  }
}

struct Card: View {
  @Binding var isShowingDetail: Bool
  @Binding var isAppeared: Bool
  let animation: Namespace.ID
  
  var body: some View {
    ZStack(alignment: .bottom) {
      VStack(spacing: 0) {
        Circle()
          .fill(.indigo)
          .matchedGeometryEffect(id: AnimationId.imageId, in: animation)
          .frame(width: Dimens.cardImageHeight, height: Dimens.cardImageHeight)
        
        Spacer()
          .frame(height: Dimens.cardForegroundHeight)
      }
      .frame(width: Dimens.cardWidth, height: Dimens.cardHeight)
      .background(
        Color.black
          .cornerRadius(Dimens.unit24)
          .matchedGeometryEffect(id: AnimationId.imageBackgroundId, in: animation)
        )
      
      VStack(alignment: .leading, spacing: 0) {
        AnimatableTitle(isAppeared: isAppeared)
          .matchedGeometryEffect(id: AnimationId.titleId, in: animation, anchor: .center)
          .padding(.bottom, Dimens.unit6)
        
        HStack(spacing: Dimens.unit12) {
          AnimatableLabels(isAppeared: isAppeared, text: Texts.points)
            .matchedGeometryEffect(id: AnimationId.label1Id, in: animation)
          AnimatableLabels(isAppeared: isAppeared, text: Texts.category)
            .matchedGeometryEffect(id: AnimationId.label2Id, in: animation)
        }
      }
      .padding(Dimens.unit16)
      .frame(width: Dimens.cardWidth, height: Dimens.cardForegroundHeight)
      .background {
        Color.white
          .cornerRadius(Dimens.unit24, corners: [.topLeft, .topRight])
          .matchedGeometryEffect(id: AnimationId.textBackgroundId, in: animation)
      }
    }
    .onAppear {
      withAnimation(.linear) {
        isAppeared = isShowingDetail
      }
    }
    .mask {
      RoundedRectangle(cornerRadius: Dimens.unit24)
        .matchedGeometryEffect(id: AnimationId.backgroundShapeId, in: animation)
    }
    .shadow(radius: Dimens.unit16)
    .onTapGesture {
      withAnimation(.hero) {
        isShowingDetail = true
      }
    }
  }
}

struct CardDetail: View {
  @Binding var isShowingDetail: Bool
  @Binding var isAppeard: Bool
  let animation: Namespace.ID
  @Binding var scaleFactor: CGFloat

  @State private var animateText: Bool = false
  
  var body: some View {
    ScrollView {
      ZStack(alignment: .bottom) {
        VStack(spacing: 0) {
          Circle()
            .fill(.indigo)
            .matchedGeometryEffect(id: AnimationId.imageId, in: animation, anchor: .top)
            .frame(width: Dimens.cardDetailHeaderHeight, height: Dimens.cardDetailHeaderHeight)
          Spacer()
            .frame(height: UIScreen.main.bounds.height - Dimens.cardImageHeight + 2 * Dimens.unit24)
        }
        .frame(maxWidth: .infinity)
        .background(
          Color.black
            .cornerRadius(0)
            .matchedGeometryEffect(id: AnimationId.imageBackgroundId, in: animation)
        )
        
        VStack(alignment: .leading, spacing: 0) {
          AnimatableTitle(isAppeared: isAppeard)
            .matchedGeometryEffect(id: AnimationId.titleId, in: animation)
            .padding(.bottom, Dimens.unit16)
          HStack(spacing: Dimens.unit12) {
            AnimatableLabels(isAppeared: isAppeard, text: Texts.points)
              .matchedGeometryEffect(id: AnimationId.label1Id, in: animation)
            AnimatableLabels(isAppeared: isAppeard, text: Texts.category)
              .matchedGeometryEffect(id: AnimationId.label2Id, in: animation)
          }
          .padding(.bottom, Dimens.unit24)
          Text(Texts.content)
            .opacity(animateText ? 1 : 0)
        }
        .padding(Dimens.unit24)
        .background {
          Color.white
            .cornerRadius(Dimens.unit24, corners: [.topLeft, .topRight])
            .matchedGeometryEffect(id: AnimationId.textBackgroundId, in: animation)
        }
      }
      .readVerticalScrollOffset {
        handleScrollEvent(offsetY: $0)
      }

    }
    .mask {
      RoundedRectangle(cornerRadius: 0)
        .matchedGeometryEffect(id: AnimationId.backgroundShapeId, in: animation)
    }
    .onAppear {
      withAnimation(.linear) {
        isAppeard = isShowingDetail
      }
      withAnimation(.linear.delay(0.2)) {
        animateText = true
      }
    }
    .onDisappear {
      withAnimation(.linear) {
        animateText = false
      }
    }
    .overlay(
        CloseButton(isShowingDetail: $isShowingDetail)
            .opacity(isAppeard ? 1 : 0)
            .padding(.top, Dimens.unit24)
            .padding(.trailing, Dimens.unit24),
        alignment: .topTrailing
    )
    .statusBarHidden(true)
    .ignoresSafeArea()
    .scrollIndicators(.hidden)
  }
  
  func handleScrollEvent(offsetY: CGFloat) {
    guard offsetY < 0 else { return }
    let originalScale: CGFloat = 1.0
    let minScale: CGFloat = 0.85
    let dismissThreshold: CGFloat = -40.0
    
    if offsetY > dismissThreshold {
      scaleFactor = originalScale + (minScale - originalScale) * (offsetY / dismissThreshold)
    } else if offsetY <= dismissThreshold {
        withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) {
          isShowingDetail = false
        }
    }
  }
}

class AnimationId {
    static let imageBackgroundId = "imageBackground"
    static let imageId = "image"
    static let titleId = "title"
    static let label1Id = "label1"
    static let label2Id = "label2"
    static let textBackgroundId = "textBackgrounud"
    static let textBackgroundShapeId = "textBackgroundShape"
    static let backgroundShapeId = "backgroundShape"
}

class Dimens {
    // MARK: - Paddings
    static let unit6: CGFloat = 6
    static let unit12: CGFloat = 12
    static let unit16: CGFloat = 16
    static let unit24: CGFloat = 24
    
    // MARK: - Card
    static let cardWidth: CGFloat = 210
    static let cardHeight: CGFloat = 205
    static let cardImageHeight: CGFloat = 92
    static let cardForegroundHeight: CGFloat = 98
    
    // MARK: - CardDetail
    static let cardDetailImageHeight: CGFloat = 240
    static let cardDetailHeaderHeight: CGFloat = 288
    
    // MARK: - Other
    static let closeButtonSize: CGFloat = 32
    
}

class Texts {
    static let content = "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet."
    static let points = "10 Points"
    static let category = "Clarification"
    static let title = "Learning: Do a\nSwiftUI tutorial"
}

struct AnimatableTitle: View {
    let isAppeared: Bool
    
    var body: some View {
        Text(Texts.title)
            .animatableSystemFont(size: isAppeared ? 32 : 16, weight: .bold)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .lineLimit(2, reservesSpace: true)
    }
}

struct AnimatableSystemFontModifier: ViewModifier, @preconcurrency Animatable {
    var size: Double
    var weight: Font.Weight
    var design: Font.Design

    var animatableData: Double {
        get { size }
        set { size = newValue }
    }

    func body(content: Content) -> some View {
        content
            .font(.system(size: size, weight: weight, design: design))
    }
}

extension View {
    func animatableSystemFont(size: Double, weight: Font.Weight = .regular, design: Font.Design = .rounded) -> some View {
        self.modifier(AnimatableSystemFontModifier(size: size, weight: weight, design: design))
    }
}

struct AnimatableLabels: View {
    let isAppeared: Bool
    let text: String
    
    var body: some View {
        VStack {
            Text(text)
                .animatableSystemFont(size: isAppeared ? 16 : 12)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color.black)
                .clipShape(RoundedRectangle(cornerRadius: isAppeared ? 12 : 8))
                .fixedSize()
        }
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

extension Animation {
    static var hero: Animation {
        .interactiveSpring(response: 0.6, dampingFraction: 0.85, blendDuration: 0.25)
    }
}

struct CloseButton: View {
    @Binding var isShowingDetail: Bool
    
    var body: some View {
        Image(systemName: "xmark")
            .font(.system(size: Dimens.unit16))
            .frame(width: Dimens.closeButtonSize, height: Dimens.closeButtonSize)
            .foregroundColor(.black)
            .background(.white)
            .clipShape(Circle())
            .onTapGesture {
                withAnimation(.hero) {
                    isShowingDetail = false
                }
            }
    }
}
