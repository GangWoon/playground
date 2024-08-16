import ViewHelper
import SwiftUI

public struct InfiniteCarousel<Datum: Hashable & Sendable, Content: View>: UIViewRepresentable {
  var data: [Datum]
  var content: (Datum) -> Content
  
  public init(
    _ data: [Datum],
    content: @escaping (Datum) -> Content
  ) {
    self.data = data
    self.content = content
  }
  
  public func makeUIView(context: Context) -> UICollectionView {
    let collectionView = buildCollectionView(coordinator: context.coordinator)
    context.coordinator.datasource = buildDataSource(collectionView)
    Task {
      /// CollectionView가 Layout된 후 사이즈를 얻기 위해서 딜레이를 줍니다.
      updateCollectionLayout(collectionView)
    }
    context.coordinator.updateTask(collectionView)
    return collectionView
  }
  
  private func buildDataSource(_ collectionView: UICollectionView) -> DataSource {
    let registration = CellRegistration { cell, _, datum in
      cell.update(content(datum))
    }
    return .init(collectionView: collectionView) { collectionView, indexPath, box in
      collectionView.dequeueConfiguredReusableCell(
        using: registration,
        for: IndexPath(row: indexPath.row % data.count, section: indexPath.section),
        item: box.value
      )
    }
  }
  
  public func updateUIView(_ collectionView: UICollectionView, context: Context) {
    guard
      let firstDatum = data.first, let lastDatum = data.last
    else { return }
    var snapshot = context.coordinator.current
    let copy = [lastDatum] + data + [firstDatum]
    snapshot.appendItems(copy.map(Box.init))
    context.coordinator.datasource?.apply(snapshot)
  }
  
  public func makeCoordinator() -> Coordinator {
    .init(parent: self)
  }
}

// MARK: - InfiniteCarousel Layout
extension InfiniteCarousel {
  private func buildFlowLayout() -> UICollectionViewFlowLayout {
    let layout = UICollectionViewFlowLayout()
    layout.scrollDirection = .horizontal
    layout.minimumLineSpacing = 0
    layout.minimumInteritemSpacing = 0
    
    return layout
  }
  
  private func buildCollectionView(coordinator: Coordinator) -> UICollectionView {
    let collectionView = UICollectionView(
      frame: .zero,
      collectionViewLayout: buildFlowLayout()
    )
    collectionView.isPagingEnabled = true
    collectionView.showsHorizontalScrollIndicator = false
    collectionView.delegate = coordinator
    
    return collectionView
  }
  
  private func updateCollectionLayout(_ collectionView: UICollectionView) {
    updateLayoutItemSize(collectionView: collectionView)
    collectionView.layoutIfNeeded()
    collectionView.scrollToItem(
      at: .init(row: 1, section: 0),
      at: .centeredHorizontally,
      animated: false
    )
  }
  
  private func updateLayoutItemSize(collectionView: UICollectionView) {
    guard
      let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout
    else { return }
    layout.itemSize = collectionView.bounds.size
  }
}

// MARK: - InfiniteCarousel Coordinator
extension InfiniteCarousel {
  typealias CellRegistration = UICollectionView.CellRegistration<WrappedCell, Datum>
  typealias SnapShot = NSDiffableDataSourceSnapshot<Section, Box<Datum>>
  typealias DataSource = UICollectionViewDiffableDataSource<Section, Box<Datum>>
  enum Section { case main }
  
  public final class Coordinator: NSObject, UICollectionViewDelegate {
    private var snapshot: SnapShot?
    fileprivate var current: SnapShot {
      if let snapshot {
        return snapshot
      } else {
        var snapshot = SnapShot()
        snapshot.appendSections([.main])
        self.snapshot = snapshot
        return snapshot
      }
    }
    var datasource: DataSource?
    private var currentIndex = 0
    private var task: Task<Void, Never>?
    
    var parent: InfiniteCarousel
    
    init(parent: InfiniteCarousel) {
      self.parent = parent
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
      let contentWidth = scrollView.contentSize.width
      let rowWidth = scrollView.bounds.size.width
      let contentOffset = scrollView.contentOffset
      guard contentWidth >= rowWidth else { return }
      updateCurrentIndex(offset: contentOffset.x, contentWidth: contentWidth)
      
      if scrollView.contentOffset.x <= 0 {
        scrollView.setContentOffset(
          CGPoint(x: contentWidth - rowWidth * 2, y: contentOffset.y),
          animated: false
        )
      } else if scrollView.contentOffset.x + rowWidth >= scrollView.contentSize.width {
        scrollView.setContentOffset(
          CGPoint(x: (-contentWidth + contentOffset.x) + rowWidth * 2, y: contentOffset.y),
          animated: false
        )
      }
    }
    
    private func updateCurrentIndex(offset: CGFloat, contentWidth: CGFloat) {
      let index = Int(round(offset / contentWidth))
      if index != currentIndex {
        currentIndex = index
      }
    }
    
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
      cancelTask()
    }
    
    private func cancelTask() {
      task?.cancel()
      task = nil
    }
    
    public func scrollViewDidEndDragging(
      _ scrollView: UIScrollView,
      willDecelerate decelerate: Bool
    ) {
      guard
        let collectionView = scrollView as? UICollectionView
      else { return }
      updateTask(collectionView)
    }
    
    func updateTask(_ scrollView: UIScrollView) {
      task = Task {
        let stream = Timer.publish(every: 2, on: .main, in: .common)
          .autoconnect()
          .eraseToAnyPublisher()
          .asyncStream
        do {
          for await _ in stream {
            scrollToNext(scrollView)
          }
          try Task.checkCancellation()
        } catch { }
      }
    }
    
    private func scrollToNext(_ scrollView: UIScrollView) {
      let rowWidth = scrollView.bounds.size.width
      var point = scrollView.contentOffset
      point.x += rowWidth
      scrollView.setContentOffset(point, animated: true)
    }
  }
}

extension InfiniteCarousel {
  struct Box<value: Hashable & Sendable>: Hashable, Sendable {
    let id: UUID = .init()
    let value: value
    
    init(value: value) {
      self.value = value
    }
  }
  
  final class WrappedCell: UICollectionViewCell {
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
}

@preconcurrency import Combine

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
