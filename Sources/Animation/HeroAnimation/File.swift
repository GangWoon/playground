import SwiftUI

struct MactedView: View {
  @State private var show: Bool = false
  @Namespace var animation
  
  var body: some View {
    ZStack {
      if !show {
        VStack(alignment: .leading, spacing: 12) {
          Text("SwiftUI")
            .font(.largeTitle.weight(.bold))
            .matchedGeometryEffect(id: "title", in: animation)
            .frame(maxWidth: .infinity, alignment: .leading)
          Text("20 sections - 3 hours".uppercased())
            .font(.footnote.weight(.semibold))
            .matchedGeometryEffect(id: "subtitle", in: animation)
          
          Text("Build an iOS app for iOS 16 with custom layouts, animations and ...")
            .font(.footnote)
            .matchedGeometryEffect(id: "text", in: animation)
        }
        .padding(20)
        .foregroundStyle(.white)
        .background {
          Color.red
            .matchedGeometryEffect(id: "background", in: animation)
        }
        .padding(20)
      } else {
        VStack(alignment: .leading, spacing: 12) {
          Spacer()
          
          Text("Build an iOS app for iOS 16 with custom layouts, animations and ...")
            .font(.footnote)
            .matchedGeometryEffect(id: "text", in: animation)
          
          Text("20 sections - 3 hours".uppercased())
            .font(.footnote.weight(.semibold))
            .matchedGeometryEffect(id: "subtitle", in: animation)
          
          Text("SwiftUI")
            .font(.largeTitle.weight(.bold))
            .matchedGeometryEffect(id: "title", in: animation)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .foregroundStyle(.black)
        .background {
          Color.blue
          .matchedGeometryEffect(id: "background", in: animation)
        }
      }
    }
    .onTapGesture {
      withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
        show.toggle()
      }
    }
  }
}

#Preview {
  MactedView()
}
