import SwiftUI

/// Defers view creation until first render.
/// Useful for Window content that shouldn't load until opened.
struct LazyView<Content: View>: View {
    let build: () -> Content

    init(_ build: @autoclosure @escaping () -> Content) {
        self.build = build
    }

    var body: some View {
        build()
    }
}
