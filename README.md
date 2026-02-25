# iOS Privacy Display (App-Scoped)

This repository implements the **maximum App Store-compliant privacy display behavior** currently possible on iPhone, based on Apple public APIs and platform restrictions.

## What this project implements

### ✅ Achievable with public APIs

1. **Real-time viewer detection in foreground app**
   - `AVFoundation` captures front camera frames.
   - `Vision` detects and tracks faces from those frames.
   - Head orientation is approximated from face landmarks and/or pose observation data.

2. **In-app privacy reaction**
   - The app computes a runtime risk score from detected viewers.
   - Sensitive content is blurred/masked when risk is above threshold.
   - Overlay updates continuously while the app is active.

3. **Fully on-device inference path**
   - Frame processing and policy logic run locally.

### ❌ Not possible with current iOS SDK boundaries

- No camera capture while app is backgrounded/locked for this use case.
- No system-wide screen overlays across other apps.
- No API for hardware viewing-angle/polarization/display emission control.

## Apple docs used for constraints and implementation boundaries

- Vision framework overview: https://developer.apple.com/documentation/vision
- `VNDetectFaceRectanglesRequest`: https://developer.apple.com/documentation/vision/vndetectfacerectanglesrequest
- AVFoundation capture pipeline: https://developer.apple.com/documentation/avfoundation/cameras_and_media_capture
- `AVCaptureSession.isMultitaskingCameraAccessSupported`: https://developer.apple.com/documentation/avfoundation/avcapturesession/ismultitaskingcameraaccesssupported
- App lifecycle / background execution constraints: https://developer.apple.com/documentation/uikit/app_and_environment/scenes/preparing_your_ui_to_run_in_the_foreground
- App sandbox/security model: https://developer.apple.com/documentation/security
- Human Interface + privacy expectations: https://developer.apple.com/design/human-interface-guidelines/privacy

> Note: This repository intentionally targets **app-local shoulder-surfing mitigation** only.

## Architecture

```text
Front Camera (AVFoundation)
   -> Vision face detection/tracking
   -> Risk engine (face count + position + pose cues)
   -> UI privacy overlay (blur + shield state)
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
