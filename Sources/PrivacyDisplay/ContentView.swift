import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = PrivacyShieldViewModel()

    var body: some View {
        ZStack {
            sensitiveDemoContent
                .blur(radius: viewModel.riskState.shouldShield ? 12 : 0)
                .animation(.easeInOut(duration: 0.15), value: viewModel.riskState.shouldShield)

            if viewModel.riskState.shouldShield {
                privacyOverlay
                    .transition(.opacity)
            }
        }
        .padding()
        .onAppear { viewModel.startMonitoring() }
        .onDisappear { viewModel.stopMonitoring() }
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

            Text("Viewers detected: \(viewModel.viewerCount)")
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
