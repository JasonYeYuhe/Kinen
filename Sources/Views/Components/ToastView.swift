import SwiftUI

/// Floating toast notification that auto-dismisses after a short delay.
struct ToastView: View {
    enum Style {
        case success, error, info

        var icon: String {
            switch self {
            case .success: "checkmark.circle.fill"
            case .error: "exclamationmark.triangle.fill"
            case .info: "info.circle.fill"
            }
        }

        var color: Color {
            switch self {
            case .success: .green
            case .error: .red
            case .info: .blue
            }
        }
    }

    let message: String
    let style: Style

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: style.icon)
                .foregroundStyle(style.color)
            Text(message)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.regularMaterial)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
    }
}

/// View modifier that shows a toast overlay with auto-dismiss.
struct ToastModifier: ViewModifier {
    @Binding var message: String?
    var style: ToastView.Style = .error

    func body(content: Content) -> some View {
        content.overlay(alignment: .top) {
            if let message {
                ToastView(message: message, style: style)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation(.easeOut) { self.message = nil }
                        }
                    }
                    .zIndex(100)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: message)
    }
}

extension View {
    func toast(_ message: Binding<String?>, style: ToastView.Style = .error) -> some View {
        modifier(ToastModifier(message: message, style: style))
    }
}
