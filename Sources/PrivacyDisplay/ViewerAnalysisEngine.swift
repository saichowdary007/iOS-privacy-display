import CoreMedia
import Foundation
import Vision

struct ViewerObservation: Sendable {
    let boundingBox: CGRect
    let yaw: Double?
    let pitch: Double?
    let confidence: Float
}

struct ViewerAnalysisResult: Sendable {
    let viewers: [ViewerObservation]
    let nearbyHumanBodies: Int

    var viewerCount: Int { viewers.count }
    var totalPotentialObservers: Int { viewers.count + nearbyHumanBodies }
}

final class ViewerAnalysisEngine {
    private let queue = DispatchQueue(label: "privacydisplay.vision.queue", qos: .userInitiated)
    private let sequenceHandler = VNSequenceRequestHandler()

    /// Uses only public Vision APIs. Faces are primary signal; human rectangles are a fallback
    /// to catch nearby observers with partially occluded faces.
    func analyze(_ sampleBuffer: CMSampleBuffer, completion: @escaping @Sendable (ViewerAnalysisResult) -> Void) {
        queue.async {
            guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
                completion(ViewerAnalysisResult(viewers: [], nearbyHumanBodies: 0))
                return
            }

            let faceRequest = VNDetectFaceRectanglesRequest()
            let bodyRequest = VNDetectHumanRectanglesRequest()
            bodyRequest.upperBodyOnly = true

            do {
                try self.sequenceHandler.perform([faceRequest, bodyRequest], on: imageBuffer, orientation: .leftMirrored)

                let faceObservations = (faceRequest.results as? [VNFaceObservation]) ?? []
                let bodyObservations = (bodyRequest.results as? [VNHumanObservation]) ?? []

                let viewers = faceObservations.map {
                    ViewerObservation(
                        boundingBox: $0.boundingBox,
                        yaw: $0.yaw?.doubleValue,
                        pitch: $0.pitch?.doubleValue,
                        confidence: $0.confidence
                    )
                }

                // Bodies with low overlap to detected face boxes are treated as additional observers.
                let extraBodies = bodyObservations.filter { body in
                    !viewers.contains { face in
                        body.boundingBox.overlapRatio(with: face.boundingBox) > 0.35
                    }
                }.count

                completion(ViewerAnalysisResult(viewers: viewers, nearbyHumanBodies: extraBodies))
            } catch {
                completion(ViewerAnalysisResult(viewers: [], nearbyHumanBodies: 0))
            }
        }
    }
}

private extension CGRect {
    var area: CGFloat { width * height }

    func overlapRatio(with other: CGRect) -> CGFloat {
        let overlap = intersection(other)
        guard !overlap.isNull else { return 0 }
        let unionArea = area + other.area - overlap.area
        guard unionArea > 0 else { return 0 }
        return overlap.area / unionArea
    }
}
