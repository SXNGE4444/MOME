import SwiftUI

struct MOMECard<Content: View>: View {
    var title: String?
    @ViewBuilder var content: Content

    init(_ title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let title {
                Text(title.uppercased())
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .tracking(0.8)
            }
            content
        }
        .padding(18)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        }
    }
}

struct StatusDot: View {
    var active: Bool

    var body: some View {
        Circle()
            .fill(active ? Color.green : Color.secondary.opacity(0.45))
            .frame(width: 8, height: 8)
    }
}

struct RiskBadge: View {
    var risk: CommandRisk

    var body: some View {
        Text(risk.rawValue.uppercased())
            .font(.system(size: 9, weight: .bold, design: .monospaced))
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(background, in: Capsule())
    }

    private var background: Color {
        switch risk {
        case .read: return .secondary.opacity(0.14)
        case .safe: return .blue.opacity(0.15)
        case .write: return .orange.opacity(0.18)
        case .release: return .purple.opacity(0.18)
        case .dangerous: return .red.opacity(0.18)
        }
    }
}

extension View {
    func momePage() -> some View {
        self
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color(nsColor: .windowBackgroundColor))
    }
}
