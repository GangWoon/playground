import SwiftUI

public struct CarouselView<Data, ID, Content>: View
where Data: RandomAccessCollection, ID: Hashable, Content: View {
  var data: Data
  var dataId: KeyPath<Data.Element, ID>
  
  var baseOffset: CGFloat {
    spacing + headspace
  }
  var spacing: CGFloat
  var headspace: CGFloat
  
  @Binding var selected: Int
  var content: (Data.Element) -> Content
  
  @State private var contentWidth: CGFloat = .zero
  @State private var offsetX: CGFloat = .zero
  @State private var dragOffset: CGFloat = .zero
  
  public init(
    data: Data,
    dataId: KeyPath<Data.Element, ID>,
    selected: Binding<Int>,
    spacing: CGFloat = 20,
    headspace: CGFloat = 20,
    content: @escaping (Data.Element) -> Content
  ) {
    self.data = data
    self.dataId = dataId
    self._selected = selected
    self.spacing = spacing
    self.headspace = headspace
    self.content = content
  }
  
  public var body: some View {
    GeometryReader { proxy in
      HStack(spacing: spacing) {
        ForEach(data, id: dataId) { datum in
          content(datum)
            .frame(
              width: contentWidth,
              height: proxy.size.height
            )
        }
      }
      .gesture(dragGesture)
      .onAppear {
        contentWidth = proxy.size.width - (headspace + spacing) * 2
        updateOffsetX(dragOffset)
      }
      .offset(x: offsetX)
      .onChange(of: dragOffset) { newValue in
        withAnimation(.easeInOut) {
          updateOffsetX(newValue)
        }
      }
    }
  }
  
  private var dragGesture: some Gesture {
    DragGesture()
      .onChanged(dragChanged)
      .onEnded(dragEnded)
  }
  
  private func dragChanged(value: DragGesture.Value) {
    var offset = contentWidth + spacing
    if value.translation.width > 0 {
      offset = min(offset, value.translation.width)
    } else {
      offset = max(-offset, value.translation.width)
    }
    dragOffset = offset
  }
  
  private func dragEnded(value: DragGesture.Value) {
    dragOffset = .zero
    let dragThreshold = contentWidth / 4
    var selected = selected
    if value.translation.width > dragThreshold {
      selected -= 1
    } else if value.translation.width < -dragThreshold {
      selected += 1
    }
    self.selected = max(0, min(selected, data.count - 1))
  }
  
  private func updateOffsetX(_ dragOffset: CGFloat) {
    offsetX = baseOffset + CGFloat(selected) * -contentWidth + CGFloat(selected) * -spacing + dragOffset
  }
}

extension CarouselView where ID == Data.Element.ID, Data.Element: Identifiable {
  public init(
    data: Data,
    selected: Binding<Int>,
    spacing: CGFloat = 20,
    headspace: CGFloat = 20,
    content: @escaping (Data.Element) -> Content
  ) {
    self.init(
      data: data,
      dataId: \.id,
      selected: selected,
      spacing: spacing,
      headspace: headspace,
      content: content
    )
  }
}

#Preview {
  @Previewable @State var selectedItem: Int = 0
  var item: [Int] = [1, 2, 3, 4]
  
  CarouselView(
    data: item,
    dataId: \.self,
    selected: $selectedItem
  ) {
    Text("\($0)")
      .frame(maxWidth: .infinity)
      .frame(height: 200)
      .background {
        Color.indigo
      }
  }
}
