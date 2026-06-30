# FormulaPad

FormulaPad is a local-first iPhone math notebook calculator built with SwiftUI.

## Product

- App name: FormulaPad
- Simplified Chinese display name: 算记
- Japanese display name: 数式メモ
- Bundle ID: `com.zhouyajie.formulapad`
- Version: `1.0.0`
- Monetization: one-time non-consumable in-app purchase, `com.zhouyajie.formulapad.pro`

## Build

```sh
ruby scripts/generate_xcodeproj.rb
xcodebuild -project FormulaPad.xcodeproj -scheme FormulaPad -destination 'generic/platform=iOS Simulator' build
```

## Test

```sh
xcodebuild -project FormulaPad.xcodeproj -scheme FormulaPad -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' test
```

## App Store Pages

GitHub Pages files live in `docs/`:

- `docs/privacy.html`
- `docs/support.html`

