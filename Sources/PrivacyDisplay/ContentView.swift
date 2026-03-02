import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel = PrivacyShieldViewModel()

    var body: some View {
        ZStack {
            sensitiveDemoContent
                .blur(radius: blurRadius)
                .animation(.easeInOut(duration: 0.15), value: viewModel.riskState.level)

            if viewModel.riskState.level == .hardShield {
                privacyOverlay
                    .transition(.opacity)
            }
        }
        .padding()
        .onAppear { viewModel.startMonitoring() }
        .onDisappear { viewModel.stopMonitoring() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { viewModel.startMonitoring() }
            else { viewModel.stopMonitoring() }
        }
    }

    private var blurRadius: CGFloat {
        switch viewModel.riskState.level {
        case .clear: return 0
        case .softBlur: return 10
        case .hardShield: return 16
        }
    }

    private var sensitiveDemoContent: some View {
        VStack(spacing: 16) {
            Text("Sensitive Account Data")
                .font(.title.bold())
            Text("Balance: $24,930.18")
                .font(.title2.monospacedDigit())
            Text("Card: •••• •••• •••• 1337")
                .font(.headline)

            Divider()

            Text("Faces detected: \(viewModel.viewerCount)")
            Text("Potential observers: \(viewModel.potentialObserverCount)")
            Text(String(format: "Risk score: %.2f", viewModel.riskState.score))
            Text(viewModel.riskState.reason)
                .foregroundStyle(viewModel.riskState.shouldShield ? .red : .green)

            Text(viewModel.multitaskingCameraMessage)
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var privacyOverlay: some View {
        VStack(spacing: 10) {
            Image(systemName: "eye.slash.fill")
                .font(.system(size: 36))
            Text("Privacy Shield Active")
                .font(.headline)
            Text("Potential shoulder-surfing detected")
                .font(.subheadline)
        }
        .padding(24)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
}

#Preview {
    ContentView()
}
