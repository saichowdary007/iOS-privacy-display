import Foundation

struct PrivacyRiskState: Equatable, Sendable {
    let score: Double
    let shouldShield: Bool
    let reason: String
}

struct PrivacyRiskEngine {
    var shieldThreshold: Double = 0.65

    func evaluate(result: ViewerAnalysisResult) -> PrivacyRiskState {
        guard result.viewerCount > 0 else {
            return PrivacyRiskState(score: 0, shouldShield: false, reason: "No viewers")
        }

        var score = 0.0

        if result.viewerCount > 1 {
            score += 0.75
        } else {
            score += 0.35
        }

        let sideViewers = result.viewers.filter { viewer in
            let xMid = viewer.boundingBox.midX
            return xMid < 0.25 || xMid > 0.75
        }.count

        if sideViewers > 0 {
            score += min(0.25, Double(sideViewers) * 0.12)
        }

        let nonFrontal = result.viewers.filter {
            guard let yaw = $0.yaw else { return false }
            return abs(yaw) > 0.25
        }.count

        if nonFrontal > 0 {
            score += min(0.20, Double(nonFrontal) * 0.10)
        }

        score = min(1.0, score)
        return PrivacyRiskState(
            score: score,
            shouldShield: score >= shieldThreshold,
            reason: score >= shieldThreshold ? "Potential shoulder-surfing detected" : "Low risk"
        )
    }
}
