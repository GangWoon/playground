import SwiftUI
import ScrollView

@main
struct playground: App {
  var body: some Scene {
    WindowGroup {
      TEst12()
    }
  }
}

struct Item: Hashable, Sendable {
  var value: Int
  var color: Color
}

struct TEst12:View {
  var item: [Item] = [
    .init(value: 0, color: .gray),
    .init(value: 1, color: .blue),
    .init(value: 2, color: .yellow),
  ]
  
  @State private var isOn: Bool = false
  
  var body: some View {
    VStack {
      Button(action: { isOn.toggle()}) {
        Text("Tapped")
      }
      if isOn {
        Text("Hi")
      } else {
        _InfiniteCarousel(item) { i in
          Text("\(i.value)")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background { i.color }
        }
      }
    }
  }
}

struct InfiniteCarousel<Datum: Hashable & Sendable, Content: View>: View {
  var data: [Datum]
  var content: (Datum) -> Content
  
  var body: some View {
    _InfiniteCarousel(
      data,
      content: content
    )
    .simultaneousGesture(
      DragGesture()
        .onChanged { _ in
          print("changed")
        }
        .onEnded { _ in
          print("End")
        }
    )
  }
}

extension _InfiniteCarousel {
  typealias CellRegistration = UICollectionView.CellRegistration<WrappedCell<Content>, Datum>
  typealias SnapShot = NSDiffableDataSourceSnapshot<Section, Box<Datum>>
  enum Section { case main }
}

extension _InfiniteCarousel.Coordinator {
  typealias DataSource = UICollectionViewDiffableDataSource<_InfiniteCarousel.Section, Box<Datum>>
}

struct _InfiniteCarousel<Datum: Hashable & Sendable, Content: View>: UIViewRepresentable {
  var fakeDataCount: Int {
    data.count + 2
  }
  var data: [Datum]
  var content: (Datum) -> Content
  @State private var task: Task<Void, Never>?
  
  @State private var currentIndex = 0
  
  init(
    _ data: [Datum],
    content: @escaping (Datum) -> Content
  ) {
    self.data = data
    self.content = content
  }
  
  func makeUIView(context: Context) -> UICollectionView {
    let layout = UICollectionViewFlowLayout()
    layout.scrollDirection = .horizontal
    layout.minimumLineSpacing = 0
    layout.minimumInteritemSpacing = 0
    
    let collectionView = UICollectionView(
      frame: .zero,
      collectionViewLayout: layout
    )
    collectionView.isPagingEnabled = true
    collectionView.showsHorizontalScrollIndicator = false
    
    collectionView.delegate = context.coordinator
    
    let registration = CellRegistration { cell, _, datum in
      cell.update(content(datum))
    }
    context.coordinator.datasource = .init(collectionView: collectionView) { collectionView, indexPath, box in
      collectionView.dequeueConfiguredReusableCell(
        using: registration,
        for: IndexPath(row: indexPath.row % data.count, section: indexPath.section),
        item: box.datum
      )
    }
    Task {
      guard
        let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout
      else { return }
      layout.itemSize = collectionView.bounds.size
    }
    
    task = buildTask(collectionView)
    return collectionView
  }
  
  private func buildTask(_ collectionView: UICollectionView) -> Task<Void, Never> {
    return Task {
      let stream = Timer.publish(every: 5, on: .main, in: .common)
        .autoconnect()
        .eraseToAnyPublisher()
        .asyncStream
      do {
        for try await _ in stream {
          try Task.checkCancellation()
          let itemSize = collectionView.contentSize.width / CGFloat(fakeDataCount)
          if currentIndex == fakeDataCount - 1 {
            currentIndex = 1
            collectionView.contentOffset.x -= itemSize * CGFloat(data.count)
            currentIndex += 1
            collectionView.scrollToItem(at: .init(row: currentIndex, section: 0), at: .centeredHorizontally, animated: true)
          } else {
            currentIndex += 1
            collectionView.scrollToItem(at: .init(row: currentIndex, section: 0), at: .centeredHorizontally, animated: true)
          }
        }
        try Task.checkCancellation()
      } catch { }
    }
  }
  
  func updateUIView(_ collectionView: UICollectionView, context: Context) {
    var snapshot: SnapShot
    if let current = context.coordinator.current {
      snapshot = current
    } else {
      snapshot = .init()
      snapshot.appendSections([.main])
    }
    
    let first = data.first!
    let last = data.last!
    
    var copy = data.map { Box(datum: $0) }
    copy.insert(.init(datum: last), at: 0)
    copy.append(.init(datum: first))
    snapshot.appendItems(copy)
    context.coordinator.datasource?.apply(snapshot)
    
    Task {
      collectionView.layoutIfNeeded()
      collectionView.scrollToItem(at: .init(row: 1, section: 0), at: .centeredHorizontally, animated: false)
    }
  }
  
  func makeCoordinator() -> Coordinator {
    .init(parent: self)
  }
  final class Coordinator: NSObject, UIScrollViewDelegate, UICollectionViewDelegate {
    var parent: _InfiniteCarousel
    var datasource: DataSource?
    var current: SnapShot?
    
    init(parent: _InfiniteCarousel) {
      self.parent = parent
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
      guard
        let collectionView = scrollView as? UICollectionView
      else { return }
      
      let itemSize = collectionView.contentSize.width / CGFloat(parent.fakeDataCount)
      
      if scrollView.contentOffset.x > itemSize * CGFloat(parent.data.count) {
        collectionView.contentOffset.x -= itemSize * CGFloat(parent.data.count)
      }
      if scrollView.contentOffset.x < 0  {
        collectionView.contentOffset.x += itemSize * CGFloat(parent.data.count)
      }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
      parent.task?.cancel()
      parent.task = nil
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
      //      parent.task = parent.buildTask(scrollView as! UICollectionView)
    }
  }
}

struct Box<Datum: Hashable & Sendable>: Hashable, Sendable {
  var id: UUID = .init()
  var datum: Datum
}

final class WrappedCell<Content: View>: UICollectionViewCell {
  var hostingController: UIHostingController<Content>!
  
  func update(_ content: Content) {
    if let hostingController {
      hostingController.rootView = content
    } else {
      hostingController = .init(rootView: content)
      hostingController.view.translatesAutoresizingMaskIntoConstraints = false
      contentView.addSubview(hostingController.view)
      hostingController.view.equalToParent()
    }
  }
}

import Combine

extension Publisher where Output: Sendable {
  public var asyncStream: AsyncStream<Output> {
    AsyncStream<Output> { continuation in
      let cancellable = self.sink { _ in
        continuation.finish()
      } receiveValue: { value in
        continuation.yield(value)
      }
      
      continuation.onTermination = { _ in
        cancellable.cancel()
      }
    }
  }
}
