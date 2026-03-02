import Foundation
import CoreMedia
import SwiftUI

@MainActor
final class PrivacyShieldViewModel: ObservableObject {
    @Published private(set) var riskState = PrivacyRiskState(score: 0, shouldShield: false, level: .clear, reason: "Idle")
    @Published private(set) var viewerCount: Int = 0
    @Published private(set) var potentialObserverCount: Int = 0

    private let cameraService: CameraCaptureService
    private let analysisEngine: ViewerAnalysisEngine
    private var riskEngine: PrivacyRiskEngine

    init(cameraService: CameraCaptureService = CameraCaptureService(),
         analysisEngine: ViewerAnalysisEngine = ViewerAnalysisEngine(),
         riskEngine: PrivacyRiskEngine = PrivacyRiskEngine()) {
        self.cameraService = cameraService
        self.analysisEngine = analysisEngine
        self.riskEngine = riskEngine
        self.cameraService.delegate = self
    }

    func startMonitoring() {
        Task { await cameraService.start() }
    }

    func stopMonitoring() {
        cameraService.stop()
        riskState = PrivacyRiskState(score: 0, shouldShield: false, level: .clear, reason: "Monitoring stopped")
        viewerCount = 0
        potentialObserverCount = 0
    }

    var multitaskingCameraMessage: String {
        cameraService.isMultitaskingSupported
        ? "Multitasking camera access is supported in this context (still foreground-only for this feature)."
        : "Multitasking camera access is not supported in this context."
    }
}

extension PrivacyShieldViewModel: CameraCaptureServiceDelegate {
    nonisolated func cameraCaptureService(_ service: CameraCaptureService, didOutput sampleBuffer: CMSampleBuffer) {
        analysisEngine.analyze(sampleBuffer) { result in
            Task { @MainActor in
                var mutableEngine = self.riskEngine
                let state = mutableEngine.evaluate(result: result)
                self.riskEngine = mutableEngine
                self.viewerCount = result.viewerCount
                self.potentialObserverCount = result.totalPotentialObservers
                self.riskState = state
            }
        }
    }

    nonisolated func cameraCaptureService(_ service: CameraCaptureService, didFail error: Error) {
        Task { @MainActor in
            self.riskState = PrivacyRiskState(score: 1, shouldShield: true, level: .hardShield, reason: "Camera error: \(error.localizedDescription)")
        }
    }
}
