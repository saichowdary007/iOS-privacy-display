# iOS Privacy Display (App-Scoped)

This repository implements the **maximum App Store-compliant privacy display behavior** currently possible on iPhone, bounded by Apple public APIs and platform restrictions.

## What is implemented (closest path to Samsung-like experience on iOS)

### 1) Real-time viewer sensing in the foreground app

- Front camera frame capture via `AVFoundation`.
- Face detection via Vision (`VNDetectFaceRectanglesRequest`).
- Additional observer fallback using Vision human-rectangle detection (`VNDetectHumanRectanglesRequest`) to catch partially occluded/side observers.
- Lightweight pose cues from `VNFaceObservation` (`yaw`, `pitch`) when available.

### 2) Adaptive, in-app privacy response

- Risk scoring from:
  - face count,
  - non-primary observer position,
  - head-turn cues,
  - extra upper-body human detections.
- Temporal smoothing to reduce UI flicker.
- Two-stage response:
  - **Soft blur** for moderate risk,
  - **Hard shield overlay** for high risk.

### 3) Lifecycle-safe behavior

- Monitoring starts when scene is active.
- Monitoring stops when app is backgrounded/inactive.
- This intentionally aligns with iOS camera and privacy expectations.

## Apple constraints this project explicitly respects

- **No system-wide protection**: only the current app’s UI can be altered.
- **No display-hardware viewing-angle control API**: app can’t control polarization/photon direction.
- **No hidden passive surveillance model**: camera usage is permission-gated, foreground, and user-visible.

## “How far can we go further?” — practical ceiling today

You can push the **logic layer** further (better risk model, smoother policies, app-specific redaction), but not the **hardware/system layer**:

- ✅ Better observer inference inside your app (Vision + policy tuning).
- ✅ Better UX reactions (blur/mask/redaction patterns).
- ❌ Background always-on camera shoulder-surfing detector.
- ❌ Cross-app overlays/protection.
- ❌ Samsung-style display optics/privacy-view physics.

## Apple docs used for implementation boundaries

- Vision framework overview: https://developer.apple.com/documentation/vision
- `VNDetectFaceRectanglesRequest`: https://developer.apple.com/documentation/vision/vndetectfacerectanglesrequest
- `VNDetectHumanRectanglesRequest`: https://developer.apple.com/documentation/vision/vndetecthumanrectanglesrequest
- AVFoundation capture pipeline: https://developer.apple.com/documentation/avfoundation/cameras_and_media_capture
- `AVCaptureSession.isMultitaskingCameraAccessSupported`: https://developer.apple.com/documentation/avfoundation/avcapturesession/ismultitaskingcameraaccesssupported
- Camera usage disclosure key (`NSCameraUsageDescription`): https://developer.apple.com/documentation/bundleresources/information_property_list/nscamerausagedescription
- App lifecycle (foreground/inactive transitions): https://developer.apple.com/documentation/uikit/app_and_environment/scenes
- Security / sandbox model: https://developer.apple.com/documentation/security
- Human Interface Guidelines privacy principles: https://developer.apple.com/design/human-interface-guidelines/privacy

## Architecture

```text
Front Camera (AVFoundation)
   -> Vision face detection + human-rectangle fallback
   -> Risk engine (count + position + pose + temporal smoothing)
   -> UI policy (soft blur / hard shield)
```

## Project layout

- `Sources/PrivacyDisplay/CameraCaptureService.swift`
- `Sources/PrivacyDisplay/ViewerAnalysisEngine.swift`
- `Sources/PrivacyDisplay/PrivacyRiskEngine.swift`
- `Sources/PrivacyDisplay/PrivacyShieldViewModel.swift`
- `Sources/PrivacyDisplay/ContentView.swift`

## Integration notes

- Add `NSCameraUsageDescription` to your app's `Info.plist`.
- Keep camera usage visible and user-initiated.
- Do not attempt hidden or background monitoring.
