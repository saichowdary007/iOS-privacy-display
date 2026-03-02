import Foundation
import CoreMedia
import SwiftUI

@MainActor
final class PrivacyShieldViewModel: ObservableObject {
    @Published private(set) var riskState = PrivacyRiskState(score: 0, shouldShield: false, reason: "Idle")
    @Published private(set) var viewerCount: Int = 0

    private let cameraService: CameraCaptureService
    private let analysisEngine: ViewerAnalysisEngine
    private let riskEngine: PrivacyRiskEngine

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
        riskState = PrivacyRiskState(score: 0, shouldShield: false, reason: "Monitoring stopped")
        viewerCount = 0
    }

    var multitaskingCameraMessage: String {
        cameraService.isMultitaskingSupported
        ? "Multitasking camera access is supported on this device/context."
        : "Multitasking camera access is not supported in this device/context."
    }
}

extension PrivacyShieldViewModel: CameraCaptureServiceDelegate {
    nonisolated func cameraCaptureService(_ service: CameraCaptureService, didOutput sampleBuffer: CMSampleBuffer) {
        analysisEngine.analyze(sampleBuffer) { [riskEngine] result in
            let state = riskEngine.evaluate(result: result)
            Task { @MainActor in
                self.viewerCount = result.viewerCount
                self.riskState = state
            }
        }
    }

    nonisolated func cameraCaptureService(_ service: CameraCaptureService, didFail error: Error) {
        Task { @MainActor in
            self.riskState = PrivacyRiskState(score: 1, shouldShield: true, reason: "Camera error: \(error.localizedDescription)")
        }
    }
}
