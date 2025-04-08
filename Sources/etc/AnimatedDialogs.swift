import SwiftUI

/// onGeometryChange, visualEffect 정리하기

public struct AnimatedDialogsView: View {
  @State private var config: DrawerConfig
  
  public init(config: DrawerConfig = .init()) {
    self.config = config
  }
  
  public var body: some View {
    NavigationStack {
      VStack {
        Spacer()
        
        DrawerButton(title: "Continue", config: $config)
      }
      .padding(15)
      .navigationTitle("Alert Drawer")
    }
    .alertDrawer(
      config: $config,
      primaryTitle: "Continue",
      secondaryTitle: "Cancel"
    ) {
      return false
    } onSecondaryClick: {
      return true
    } content: {
      VStack(alignment: .leading, spacing: 15) {
        Image(systemName: "exclamationmark.circle")
          .font(.largeTitle)
          .foregroundStyle(.red)
          .frame(maxWidth: .infinity, alignment: .leading)
        
        Text("Are you sure?")
          .font(.title2.bold())
        
        Text("You haven't backed up your wallet yet.\nIf you remove it, you could lose access forever. We suggest tapping Cancel and backing up your wallet first with a valid recovery method.")
          .foregroundStyle(.gray)
          .fixedSize(horizontal: false, vertical: true)
          .frame(width: 300)
      }
    }
  }
}

public struct DrawerConfig {
  var tint: Color
  var foreground: Color
  var clipShape: AnyShape
  var animation: Animation
  
  fileprivate(set) var isPresented: Bool = false
  fileprivate(set) var hideSourceButton: Bool = false
  fileprivate(set) var sourceRect: CGRect = .zero
  
  public init(
    tint: Color = .pink,
    foreground: Color = .white,
    clipShape: AnyShape = .init(.capsule),
    animation: Animation = .snappy(duration: 0.35, extraBounce: 0)
  ) {
    self.tint = tint
    self.foreground = foreground
    self.clipShape = clipShape
    self.animation = animation
  }
}
struct DrawerButton: View {
  var title: String
  @Binding var config: DrawerConfig
  
  var body: some View {
    Button {
      config.hideSourceButton = true
      withAnimation(config.animation) {
        config.isPresented = true
      }
    } label: {
      Text(title)
        .fontWeight(.semibold)
        .foregroundStyle(config.foreground)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(config.tint, in: config.clipShape)
    }
    .buttonStyle(ScaledButtonStyle())
    .opacity(config.hideSourceButton ? 0 : 1)
    .onGeometryChange(for: CGRect.self) {
      $0.frame(in: .global)
    } action: { newValue in
      config.sourceRect = newValue
    }
  }
}

extension View {
  @ViewBuilder
  func alertDrawer<Content: View>(
    config: Binding<DrawerConfig>,
    primaryTitle: String,
    secondaryTitle: String,
    opPrimaryClick: @escaping () -> Bool,
    onSecondaryClick: @escaping () -> Bool,
    @ViewBuilder content: @escaping () -> Content
  ) -> some View {
    self
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .overlay {
        GeometryReader { proxy in
          let isPresented = config.wrappedValue.isPresented
          ZStack {
            if isPresented {
              Rectangle()
                .fill(.black.opacity(0.5))
                .transition(.opacity)
                .onTapGesture {
                  withAnimation(
                    config.wrappedValue.animation,
                    completionCriteria: .logicallyComplete
                  ) {
                    config.wrappedValue.isPresented = false
                  } completion: {
                    config.wrappedValue.hideSourceButton = false
                  }
                }
            }
            
            if config.wrappedValue.hideSourceButton {
              AlertDrawerContent(
                proxy: proxy,
                primaryTitle: primaryTitle,
                secondayTitle: secondaryTitle,
                onPrimaryClick: opPrimaryClick,
                onSecondaryClick: onSecondaryClick,
                config: config,
                content: content
              )
              .transition(.identity)
              .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
          }
          .ignoresSafeArea()
        }
      }
  }
}

fileprivate struct AlertDrawerContent<Content: View>: View {
  var proxy: GeometryProxy
  var primaryTitle: String
  var secondayTitle: String
  var onPrimaryClick: () -> Bool
  var onSecondaryClick: () -> Bool
  
  @Binding var config: DrawerConfig
  @ViewBuilder var content: Content
  
  var body: some View {
    let isPresented = config.isPresented
    let sourceRect = config.sourceRect
    let maxY = proxy.frame(in: .global).maxY
    let bottomPadding = 10.0
    
    VStack(spacing: 15) {
      content
        .overlay(alignment: .topTrailing) {
          Button {
            dismissDrawer()
          } label: {
            Image(systemName: "xmark.circle.fill")
              .font(.title2)
              .foregroundStyle(.primary, .gray.opacity(0.15))
          }
        }
        .compositingGroup()
        .opacity(isPresented ? 1 : 0)
      
      HStack(spacing: 10) {
        GeometryReader { proxy in
          Button(action: {
            if onSecondaryClick() {
              dismissDrawer()
            }
          }) {
            Text(secondayTitle)
              .fontWeight(.semibold)
              .foregroundStyle(.primary)
              .frame(maxWidth: .infinity, maxHeight: .infinity)
              .background(.ultraThinMaterial, in: config.clipShape)
          }
          .offset(fixedLocation(proxy))
          .opacity(isPresented ? 1 : 0 )
        }
        .frame(height: config.sourceRect.height)
        
        GeometryReader { proxy in
          Button(
            action: {
              if onPrimaryClick() {
                dismissDrawer()
              }
            }
          ) {
            Text(primaryTitle)
              .fontWeight(.semibold)
              .foregroundStyle(config.foreground)
              .frame(maxWidth: .infinity, maxHeight: .infinity)
              .background(config.tint, in: config.clipShape)
          }
          .frame(
            width: isPresented ? nil : sourceRect.width,
            height: isPresented ? nil : sourceRect.height
          )
          .offset(fixedLocation(proxy))
        }
        .frame(height: config.sourceRect.height)
        .zIndex(1)
      }
      .buttonStyle(ScaledButtonStyle())
      .padding(.top, 10)
    }
    .padding([.horizontal, .top], 20)
    .padding(.bottom, 15)
    .frame(
      width: isPresented ? nil : sourceRect.width,
      height: isPresented ? nil : sourceRect.height,
      alignment: .top
    )
    .background(.background)
    .clipShape(.rect(cornerRadius: sourceRect.height / 2))
    .shadow(color: .black.opacity(isPresented ? 0.1 : 0), radius: 5, x: 5, y: 5)
    .shadow(color: .black.opacity(isPresented ? 0.1 : 0), radius: 5, x: -5, y: -5)
    .padding(.horizontal, isPresented ? 20 : 0)
    .visualEffect { content, proxy in
      content
        .offset(
          x: isPresented ? 0 : sourceRect.minX,
          y: (isPresented ? maxY - bottomPadding : sourceRect.maxY) - proxy.size.height
        )
    }
    .allowsHitTesting(config.hideSourceButton)
  }
  
  private func dismissDrawer() {
    withAnimation(config.animation, completionCriteria: .logicallyComplete) {
      config.isPresented = false
    } completion: {
      config.hideSourceButton = false
    }
  }
  
  private func fixedLocation(_ proxy: GeometryProxy) -> CGSize {
    let isPresented = config.isPresented
    let sourceRect = config.sourceRect
    return CGSize(
      width: isPresented ? 0 : (sourceRect.minX - proxy.frame(in: .global).minX),
      height: isPresented ? 0 : (sourceRect.minY - proxy.frame(in: .global).minY)
    )
  }
}

#Preview {
  AnimatedDialogsView()
}

fileprivate struct ScaledButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed ? 0.95 : 1)
      .animation(.linear(duration: 0.1), value: configuration.isPressed)
  }
}
