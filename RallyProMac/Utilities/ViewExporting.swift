import SwiftUI
import AppKit
import UniformTypeIdentifiers

@MainActor
enum ExporterError: Error {
    case userCancelled
    case pngEncodingFailed
    case noWritePermission(URL)
}

@MainActor
struct ViewExporter {
    static func exportAsPNGs(pages: [(title: String, view: AnyView)], baseName: String) throws {
        let open = NSOpenPanel()
        open.canChooseDirectories = true
        open.canChooseFiles = false
        open.allowsMultipleSelection = false
        open.canCreateDirectories = true
        open.allowedContentTypes = [.folder]
        open.prompt = "Export"

        guard open.runModal() == .OK, let folder = open.url else { throw ExporterError.userCancelled }

        let accessing = folder.startAccessingSecurityScopedResource()
        defer { if accessing { folder.stopAccessingSecurityScopedResource() } }

        guard FileManager.default.isWritableFile(atPath: folder.path) else {
            throw ExporterError.noWritePermission(folder)
        }

        let size = CGSize(width: 1600, height: 2000)
        for (title, anyView) in pages {
            let img = hostingSnapshot(for: anyView, size: size)
            let safe = sanitizedFilename(title)
            let url = folder.appendingPathComponent("\(baseName)-\(safe).png")
            try writePNG(img, to: url)
        }
    }

    private static func hostingSnapshot(for view: AnyView, size: CGSize) -> NSImage {
        let wrapped = view
            .frame(width: size.width, height: size.height)
            .background(Color.white)

        let hosting = NSHostingView(rootView: wrapped)
        hosting.frame = NSRect(origin: .zero, size: size)
        hosting.wantsLayer = true
        hosting.layer?.contentsScale = NSScreen.main?.backingScaleFactor ?? 2
        hosting.layoutSubtreeIfNeeded()
        hosting.display()

        guard let rep = hosting.bitmapImageRepForCachingDisplay(in: hosting.bounds) else {
            return NSImage(size: size)
        }
        rep.size = size
        hosting.cacheDisplay(in: hosting.bounds, to: rep)

        let image = NSImage(size: size)
        image.addRepresentation(rep)
        return image
    }

    private static func writePNG(_ image: NSImage, to url: URL) throws {
        guard
            let tiff = image.tiffRepresentation,
            let rep = NSBitmapImageRep(data: tiff),
            let data = rep.representation(using: .png, properties: [:])
        else { throw ExporterError.pngEncodingFailed }

        try data.write(to: url, options: .atomic)
    }

    private static func sanitizedFilename(_ name: String) -> String {
        let invalid = CharacterSet(charactersIn: "/\\?%*|\"<>:")
        return name.components(separatedBy: invalid).joined().replacingOccurrences(of: " ", with: "_")
    }
}
