import SwiftUI

// A preference key for reporting a view’s size.
struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        let next = nextValue()
        value = CGSize(width: max(value.width, next.width),
                       height: max(value.height, next.height))
    }
}

extension View {
    /// Adds a background GeometryReader to capture the view’s size into the provided binding.
    func captureSize(_ binding: Binding<CGSize>) -> some View {
        background(
            GeometryReader { proxy in
                Color.clear
                    .preference(key: SizePreferenceKey.self, value: proxy.size)
            }
        )
        .onPreferenceChange(SizePreferenceKey.self) { newSize in
            binding.wrappedValue = newSize
        }
    }
    
    /// Renders the view as a UIImage using the provided target size.
    func snapshot(targetSize: CGSize) -> UIImage {
        let controller = UIHostingController(rootView: self.ignoresSafeArea())
        
        // Use the target size directly (or adjust as needed)
        let adjustedSize = targetSize
        
        // Configure the hosting controller's view
        controller.view.frame = CGRect(origin: .zero, size: adjustedSize)
        controller.view.backgroundColor = .clear
        controller.view.insetsLayoutMarginsFromSafeArea = false
        controller.view.layoutMargins = .zero
        
        // Layout the view
        controller.view.setNeedsLayout()
        controller.view.layoutIfNeeded()
        
        // Render the view hierarchy into an image
        let renderer = UIGraphicsImageRenderer(size: adjustedSize)
        return renderer.image { _ in
            controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
}
