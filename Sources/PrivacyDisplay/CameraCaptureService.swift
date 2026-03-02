import AVFoundation
import CoreMedia
import Foundation

protocol CameraCaptureServiceDelegate: AnyObject {
    func cameraCaptureService(_ service: CameraCaptureService, didOutput sampleBuffer: CMSampleBuffer)
    func cameraCaptureService(_ service: CameraCaptureService, didFail error: Error)
}

final class CameraCaptureService: NSObject {
    weak var delegate: CameraCaptureServiceDelegate?

    private let session = AVCaptureSession()
    private let output = AVCaptureVideoDataOutput()
    private let queue = DispatchQueue(label: "privacydisplay.camera.queue", qos: .userInitiated)

    var isMultitaskingSupported: Bool {
        session.isMultitaskingCameraAccessSupported
    }

    func start() async {
        do {
            try await configureSessionIfNeeded()
            session.startRunning()
        } catch {
            delegate?.cameraCaptureService(self, didFail: error)
        }
    }

    func stop() {
        guard session.isRunning else { return }
        session.stopRunning()
    }

    private func configureSessionIfNeeded() async throws {
        guard session.inputs.isEmpty else { return }

        let status = AVCaptureDevice.authorizationStatus(for: .video)
        if status == .notDetermined {
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            guard granted else { throw NSError(domain: "CameraCaptureService", code: 1) }
        } else if status != .authorized {
            throw NSError(domain: "CameraCaptureService", code: 2)
        }

        session.beginConfiguration()
        defer { session.commitConfiguration() }

        session.sessionPreset = .vga640x480

        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            throw NSError(domain: "CameraCaptureService", code: 3)
        }

        let input = try AVCaptureDeviceInput(device: camera)
        guard session.canAddInput(input) else {
            throw NSError(domain: "CameraCaptureService", code: 4)
        }
        session.addInput(input)

        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: queue)

        guard session.canAddOutput(output) else {
            throw NSError(domain: "CameraCaptureService", code: 5)
        }
        session.addOutput(output)

        if let connection = output.connection(with: .video), connection.isVideoOrientationSupported {
            connection.videoOrientation = .portrait
        }
    }
}

extension CameraCaptureService: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        delegate?.cameraCaptureService(self, didOutput: sampleBuffer)
    }
}
