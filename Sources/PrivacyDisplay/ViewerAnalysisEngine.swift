import CoreMedia
import Foundation
import Vision

struct ViewerObservation: Sendable {
    let boundingBox: CGRect
    let yaw: Double?
    let pitch: Double?
}

struct ViewerAnalysisResult: Sendable {
    let viewers: [ViewerObservation]

    var viewerCount: Int { viewers.count }
}

final class ViewerAnalysisEngine {
    private let queue = DispatchQueue(label: "privacydisplay.vision.queue", qos: .userInitiated)
    private let sequenceHandler = VNSequenceRequestHandler()

    func analyze(_ sampleBuffer: CMSampleBuffer, completion: @escaping @Sendable (ViewerAnalysisResult) -> Void) {
        queue.async {
            guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
                completion(ViewerAnalysisResult(viewers: []))
                return
            }

            let request = VNDetectFaceRectanglesRequest()
            do {
                try self.sequenceHandler.perform([request], on: imageBuffer, orientation: .leftMirrored)
                let faceObservations = (request.results as? [VNFaceObservation]) ?? []

                let viewers = faceObservations.map {
                    ViewerObservation(
                        boundingBox: $0.boundingBox,
                        yaw: $0.yaw?.doubleValue,
                        pitch: $0.pitch?.doubleValue
                    )
                }
                completion(ViewerAnalysisResult(viewers: viewers))
            } catch {
                completion(ViewerAnalysisResult(viewers: []))
            }
        }
    }
}
