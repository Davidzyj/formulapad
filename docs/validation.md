# Validation Log

## Environment

- Date: 2026-06-30; screenshot set expanded on 2026-07-01
- Xcode: 26.2
- Swift: 6.2.3 compiler, project set to Swift 5 mode
- Simulator used for tests: iPhone 17, iOS 26.2
- Simulator used for screenshot verification: TrailLevel 6.5, iOS 26.2

## Build

Command:

```sh
xcodebuild -project FormulaPad.xcodeproj -scheme FormulaPad -destination 'generic/platform=iOS Simulator' build
```

Result:

- Build succeeded.
- Rebuilt successfully after regenerating the Xcode project from `scripts/generate_xcodeproj.rb`.

## Tests

Command:

```sh
xcodebuild -project FormulaPad.xcodeproj -scheme FormulaPad -destination 'platform=iOS Simulator,id=1BFE5DF8-611F-4361-A92A-5B3ED60D7F99' test
```

Result:

- Test succeeded.
- 5 tests passed.
- 0 failures.
- Re-ran successfully after project regeneration.
- Re-ran successfully on TrailLevel 6.5 after adding screenshot automation.
- Re-ran successfully on TrailLevel 6.5 after adding multilingual screenshot capture.

## Info.plist

Command:

```sh
plutil -lint FormulaPad/Resources/Info.plist
```

Result:

- `FormulaPad/Resources/Info.plist: OK`

Confirmed keys:

- `ITSAppUsesNonExemptEncryption => false`
- `UIUserInterfaceStyle => Light`
- `CFBundleShortVersionString => $(MARKETING_VERSION)`

Target build settings confirm:

- `INFOPLIST_FILE = FormulaPad/Resources/Info.plist`
- `MARKETING_VERSION = 1.0.0`
- `PRODUCT_BUNDLE_IDENTIFIER = com.zhouyajie.formulapad`
- `TARGETED_DEVICE_FAMILY = 1`
- `SUPPORTED_PLATFORMS = iphoneos iphonesimulator`
- `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon`

The source Info.plist intentionally does not hard-code `UIDeviceFamily`; Xcode derives the built app value from `TARGETED_DEVICE_FAMILY = 1`.

Built app Info.plist confirms:

- `CFBundleIdentifier => com.zhouyajie.formulapad`
- `CFBundleShortVersionString => 1.0.0`
- `ITSAppUsesNonExemptEncryption => false`
- `UIDeviceFamily` is present in the built product
- `UIUserInterfaceStyle => Light`

## StoreKit Scheme

The shared scheme contains:

```xml
<StoreKitConfigurationFileReference
   identifier = "../../../FormulaPad/Resources/StoreKit/FormulaPad.storekit">
</StoreKitConfigurationFileReference>
```

## App Icon

Path:

```text
FormulaPad/Resources/Assets.xcassets/AppIcon.appiconset/FormulaPadIcon.png
```

Confirmed:

- Width: 1024
- Height: 1024
- Alpha: no
- Format: RGB PNG

## GitHub

- Repository created: `https://github.com/Davidzyj/formulapad`
- Pages URL: `https://davidzyj.github.io/formulapad/`
- Pages source: `main:/docs`

## App Store Screenshots

Command:

```sh
scripts/capture_app_store_screenshots.sh
```

Simulator:

- TrailLevel 6.5
- UDID: `FC791334-2F7B-48AD-93E2-44DF010891BE`

Result:

- `screenshots/6.5/zh-Hans/01-calculate.png`: 1242x2688, alpha=no
- `screenshots/6.5/zh-Hans/02-history.png`: 1242x2688, alpha=no
- `screenshots/6.5/zh-Hans/03-notes.png`: 1242x2688, alpha=no
- `screenshots/6.5/zh-Hans/04-templates.png`: 1242x2688, alpha=no
- `screenshots/6.5/zh-Hans/05-convert.png`: 1242x2688, alpha=no
- `screenshots/6.5/zh-Hans/06-plot.png`: 1242x2688, alpha=no
- `screenshots/6.5/en/01-calculate.png`: 1242x2688, alpha=no
- `screenshots/6.5/en/02-history.png`: 1242x2688, alpha=no
- `screenshots/6.5/en/03-notes.png`: 1242x2688, alpha=no
- `screenshots/6.5/en/04-templates.png`: 1242x2688, alpha=no
- `screenshots/6.5/en/05-convert.png`: 1242x2688, alpha=no
- `screenshots/6.5/en/06-plot.png`: 1242x2688, alpha=no
- `screenshots/6.5/ja/01-calculate.png`: 1242x2688, alpha=no
- `screenshots/6.5/ja/02-history.png`: 1242x2688, alpha=no
- `screenshots/6.5/ja/03-notes.png`: 1242x2688, alpha=no
- `screenshots/6.5/ja/04-templates.png`: 1242x2688, alpha=no
- `screenshots/6.5/ja/05-convert.png`: 1242x2688, alpha=no
- `screenshots/6.5/ja/06-plot.png`: 1242x2688, alpha=no

OCR checks passed for expected page content. Contact sheets reviewed at:

```text
screenshots/6.5/zh-Hans/contact-sheet.png
screenshots/6.5/en/contact-sheet.png
screenshots/6.5/ja/contact-sheet.png
```
