import SwiftUI
import AppKit

/// Renders SwiftUI content inside a borderless, non-activating NSPanel child
/// window anchored to a SwiftUI-global frame. Use as a sibling view (e.g.,
/// `.background` of any view) — it occupies zero layout space and never
/// affects parent sizing.
///
/// Why this exists: SwiftUI `.overlay` / sibling content cannot be reliably
/// made opaque on macOS — the compositing tree leaks translucency even with
/// NSView+isOpaque backings. A child NSPanel is its own NSWindow, so its
/// background is genuinely opaque and never composites with the parent.
/// Non-activating means clicks reach the panel without resigning first
/// responder of the underlying field — keyboard focus stays on the search box.
///
/// Anchor frame must be in SwiftUI's `.global` coordinate space (top-down,
/// origin at top-left of the window's content view).
struct AnchoredSuggestionPopup<Content: View>: NSViewRepresentable {
    @Binding var isVisible: Bool
    /// Anchor frame in SwiftUI global coords (top-down, window content space).
    let anchorFrame: CGRect
    let width: CGFloat
    let height: CGFloat
    /// Vertical gap between the anchor's bottom edge and the panel's top edge.
    var gap: CGFloat = 4
    /// Horizontal alignment of the panel relative to the anchor frame.
    var horizontalAlignment: HorizontalAlignment = .trailing
    @ViewBuilder let content: () -> Content

    enum HorizontalAlignment {
        case leading, trailing
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> NSView {
        let v = HostView()
        v.coordinator = context.coordinator
        context.coordinator.hostView = v
        return v
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        let host = nsView as! HostView
        host.coordinator = context.coordinator
        context.coordinator.hostView = host
        context.coordinator.preferredSize = NSSize(width: width, height: height)
        context.coordinator.gap = gap
        context.coordinator.horizontalAlignment = horizontalAlignment
        context.coordinator.anchorFrame = anchorFrame
        context.coordinator.setContent(AnyView(content()))
        context.coordinator.setVisible(isVisible)
    }

    static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
        coordinator.tearDown()
    }

    @MainActor
    final class Coordinator {
        weak var hostView: HostView?
        var preferredSize: NSSize = .zero
        var gap: CGFloat = 4
        var horizontalAlignment: HorizontalAlignment = .trailing
        var anchorFrame: CGRect = .zero
        private var panel: NSPanel?
        private var hostingController: NSHostingController<AnyView>?
        private var visible: Bool = false

        func setContent(_ view: AnyView) {
            if let hc = hostingController {
                hc.rootView = view
            } else {
                hostingController = NSHostingController(rootView: view)
            }
            if let panel, let hc = hostingController, panel.contentViewController !== hc {
                panel.contentViewController = hc
            }
        }

        func setVisible(_ shouldShow: Bool) {
            if shouldShow {
                show()
            } else {
                hide()
            }
        }

        private func ensurePanel() -> NSPanel? {
            if let panel { return panel }
            guard let hc = hostingController else { return nil }
            let p = NSPanel(
                contentRect: NSRect(origin: .zero, size: preferredSize),
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: true
            )
            p.isFloatingPanel = true
            p.hidesOnDeactivate = false
            p.becomesKeyOnlyIfNeeded = true
            p.isReleasedWhenClosed = false
            p.hasShadow = true
            p.contentViewController = hc
            // SwiftUI content paints its own opaque bg.
            p.backgroundColor = .clear
            p.isOpaque = false
            p.level = .popUpMenu
            panel = p
            return p
        }

        private func show() {
            guard let host = hostView, let parentWindow = host.window else { return }
            guard let panel = ensurePanel() else { return }

            reposition()

            if !visible {
                if panel.parent !== parentWindow {
                    panel.parent?.removeChildWindow(panel)
                    parentWindow.addChildWindow(panel, ordered: .above)
                }
                panel.orderFront(nil)
                visible = true
            } else {
                panel.orderFront(nil)
            }
        }

        private func hide() {
            guard visible else { return }
            visible = false
            if let panel {
                panel.parent?.removeChildWindow(panel)
                panel.orderOut(nil)
            }
        }

        func reposition() {
            guard let host = hostView, let parentWindow = host.window, let panel else { return }
            // SwiftUI .global coords are top-down with origin at the window's
            // content-view top-left. AppKit window coords are bottom-up.
            // Translate using the content view's height.
            guard let contentView = parentWindow.contentView else { return }
            let contentHeight = contentView.bounds.height
            let bottomUpY = contentHeight - anchorFrame.maxY
            let anchorRectInWindow = NSRect(
                x: anchorFrame.minX,
                y: bottomUpY,
                width: anchorFrame.width,
                height: anchorFrame.height
            )
            let anchorRectOnScreen = parentWindow.convertToScreen(anchorRectInWindow)
            let x: CGFloat
            switch horizontalAlignment {
            case .leading:
                x = anchorRectOnScreen.minX
            case .trailing:
                x = anchorRectOnScreen.maxX - preferredSize.width
            }
            let y = anchorRectOnScreen.minY - preferredSize.height - gap
            let frame = NSRect(origin: NSPoint(x: x, y: y), size: preferredSize)
            panel.setFrame(frame, display: true)
        }

        func tearDown() {
            hide()
            panel = nil
            hostingController = nil
        }
    }

    final class HostView: NSView {
        weak var coordinator: Coordinator?

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            DispatchQueue.main.async { [weak self] in
                self?.coordinator?.reposition()
            }
        }
    }
}

/// PreferenceKey for capturing a SwiftUI view's frame in `.global` coords.
struct SearchFieldFramePreferenceKey: PreferenceKey {
    static let defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        let next = nextValue()
        if next != .zero { value = next }
    }
}
