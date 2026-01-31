import SwiftUI
import AppKit
import PencilKit

#if os(macOS) && !targetEnvironment(macCatalyst)
class SimpleCanvasView: NSView {
    var tool: PKTool = PKInkingTool(.pen, color: .black, width: 1)
    var backgroundColor: NSColor = .clear {
        didSet {
            self.wantsLayer = true
            self.layer?.backgroundColor = backgroundColor.cgColor
            needsDisplay = true
        }
    }

    private var paths: [(NSBezierPath, NSColor, CGFloat)] = []
    private var currentPath: NSBezierPath?

    var drawing: SimpleDrawing {
        get { SimpleDrawing(paths: paths, bounds: bounds) }
        set {
            paths = newValue.paths
            needsDisplay = true
        }
    }

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        let newPath = NSBezierPath()
        newPath.move(to: point)
        currentPath = newPath

        var color = NSColor.labelColor
        var width: CGFloat = 1.0

        if let inkingTool = tool as? PKInkingTool {
            color = inkingTool.color
            width = inkingTool.width
        }

        paths.append((newPath, color, width))
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        currentPath?.line(to: point)
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        currentPath = nil
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        if backgroundColor != .clear {
            backgroundColor.setFill()
            dirtyRect.fill()
        }
        for (path, color, width) in paths {
            color.setStroke()
            path.lineWidth = width
            path.stroke()
        }
    }

    func clear() {
        paths = []
        needsDisplay = true
    }
}

struct SimpleDrawing {
    var paths: [(NSBezierPath, NSColor, CGFloat)]
    var bounds: CGRect

    func image(from rect: CGRect, scale: CGFloat) -> NSImage {
        let img = NSImage(size: rect.size)
        img.lockFocus()

        for (path, color, width) in paths {
            color.setStroke()
            path.lineWidth = width
            path.stroke()
        }
        img.unlockFocus()
        return img
    }
}

struct CanvasView: NSViewRepresentable {
    let canvasView: SimpleCanvasView

    func makeNSView(context: Context) -> SimpleCanvasView {
        canvasView.backgroundColor = .clear
        return canvasView
    }

    func updateNSView(_ nsView: SimpleCanvasView, context: Context) {}
}
#endif
