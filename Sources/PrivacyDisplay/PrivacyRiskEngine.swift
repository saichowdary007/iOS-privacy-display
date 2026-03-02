import Foundation

enum PrivacyShieldLevel: String, Equatable, Sendable {
    case clear
    case softBlur
    case hardShield
}

struct PrivacyRiskState: Equatable, Sendable {
    let score: Double
    let shouldShield: Bool
    let level: PrivacyShieldLevel
    let reason: String
}

struct PrivacyRiskEngine {
    var enableSmoothing: Bool = true
    var hardShieldThreshold: Double = 0.75
    var softBlurThreshold: Double = 0.45
    var smoothFactor: Double = 0.25

    private(set) var smoothedScore: Double = 0

    mutating func evaluate(result: ViewerAnalysisResult) -> PrivacyRiskState {
        let raw = rawScore(result: result)
        if enableSmoothing {
            smoothedScore = (1 - smoothFactor) * smoothedScore + smoothFactor * raw
        } else {
            smoothedScore = raw
        }

        if smoothedScore >= hardShieldThreshold {
            return PrivacyRiskState(
                score: smoothedScore,
                shouldShield: true,
                level: .hardShield,
                reason: "Multiple or suspicious observers detected"
            )
        }

        if smoothedScore >= softBlurThreshold {
            return PrivacyRiskState(
                score: smoothedScore,
                shouldShield: true,
                level: .softBlur,
                reason: "Possible shoulder-surfing risk"
            )
        }

        return PrivacyRiskState(score: smoothedScore, shouldShield: false, level: .clear, reason: "Low risk")
    }

    private func rawScore(result: ViewerAnalysisResult) -> Double {
        guard result.totalPotentialObservers > 0 else { return 0 }

        var score = 0.0

        if result.viewerCount > 1 { score += 0.60 }
        else if result.viewerCount == 1 { score += 0.25 }

        if result.nearbyHumanBodies > 0 {
            score += min(0.30, Double(result.nearbyHumanBodies) * 0.18)
        }

        let sideViewers = result.viewers.filter { viewer in
            let xMid = viewer.boundingBox.midX
            return xMid < 0.25 || xMid > 0.75
        }.count
        if sideViewers > 0 {
            score += min(0.20, Double(sideViewers) * 0.10)
        }

        let turnedHead = result.viewers.filter {
            guard let yaw = $0.yaw else { return false }
            return abs(yaw) > 0.25
        }.count
        if turnedHead > 0 {
            score += min(0.20, Double(turnedHead) * 0.10)
        }

        return min(1.0, score)
    }
}
