import SwiftUI

#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// The tire, with the light canvas already removed so it can sit on either background.
public struct BrandMark: View {
    private let size: CGFloat

    public init(size: CGFloat = 28) {
        self.size = size
    }

    public var body: some View {
        // ImageRenderer skips Image(name:bundle:) for a package resource
        loaded
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }

    private var loaded: Image {
        let url = Bundle.module.url(forResource: "brand-mark", withExtension: "png")
        #if os(macOS)
        if let url, let image = NSImage(contentsOf: url) {
            return Image(nsImage: image)
        }
        #else
        if let url, let image = UIImage(contentsOfFile: url.path) {
            return Image(uiImage: image)
        }
        #endif
        return Image("brand-mark", bundle: .module)
    }
}
