import Foundation

func syncwork() {
  Task {
    // nonisolated + async
    ///  구조적 동시성 사용하지 않을 경우에는 nonisolated + async 함수가 글로벌 엑터에서 실행됨을 보장함.
    let result = await verySlowJob2()
    print(result)
  }
  
  
  Task {
    // async let + nonisolated
    /// 구조적 동시성을 활용한 방식
    async let result = verySlowJob()
    print(await result)
  }
}

func gcd() {
  DispatchQueue.global().async {
    /// <-
    ///
    DispatchQueue.main.async {
      /// <-
    }
  }
  
  Task.detached {
    // <-
    
    Task { @MainActor in
      // <-
    }
  }
}

nonisolated func verySlowJob() -> String {
  for _ in 0...1000000 {
    autoreleasepool { let _ = URL(string: "https://www.google.com") }
  }
  return "Good Job :)"
}


/// nonisolated + async -> global actor
nonisolated func verySlowJob2() async -> String {
  for _ in 0...1000000 {
    autoreleasepool { let _ = URL(string: "https://www.google.com") }
  }
  return "Good Job :)"
}
