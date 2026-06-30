# Test Cases

## Automated Tests

Command:

```sh
xcodebuild -project FormulaPad.xcodeproj -scheme FormulaPad -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' test
```

Current result:

- 5 tests passed
- 0 failures

Coverage:

- Compound interest expression parsing
- Variable assignment and reuse
- Degree-mode sine calculation
- Discount template
- Length unit conversion

## Manual Acceptance Tests

### Calculate And History

1. Open Calculate.
2. Enter `20000 * (1 + 0.035)^3`.
3. Tap Calculate.
4. Confirm result is `22174.3575`.
5. Open History.
6. Confirm the expression and result are visible.
7. Tap Reuse.
8. Confirm Calculate opens with the expression restored.

### Variables

1. Enter `price = 299; count = 12; price * count`.
2. Tap Calculate.
3. Confirm result is `3588`.
4. Confirm variable chips show `price=299` and `count=12`.

### Scientific Functions

1. Set angle mode to Degrees.
2. Enter `sin(30)`.
3. Confirm result is `0.5`.
4. Set angle mode to Radians.
5. Recalculate and confirm the result changes.

### Notes Pro Flow

1. Try Save Note without Pro.
2. Confirm Pro purchase sheet opens.
3. In StoreKit test mode, purchase Pro.
4. Calculate again and tap Save Note.
5. Enter a title and remarks.
6. Save and confirm the note appears in Notes.
7. Edit the note and confirm changes persist.

### Templates

1. Open Tools > Templates.
2. Open Discount.
3. Enter original price `299`, discount `15`.
4. Calculate and confirm result `254.15`.
5. Save to History and confirm it appears.

### Unit Conversion

1. Open Tools > Convert.
2. Select Length.
3. Enter `1500`.
4. Convert Meter to Kilometer.
5. Confirm result is `1.5 Kilometer`.
6. Save to History and confirm it appears.

### Plot Pro Flow

1. Open Tools > Plot without Pro.
2. Confirm Pro gate appears.
3. Unlock Pro in StoreKit test mode.
4. Enter `x^2`.
5. Tap Plot and confirm a curve appears.
6. Save Plot and confirm History receives the entry.

### Language

1. Open Settings.
2. Set language to Simplified Chinese.
3. Confirm tab titles and screen labels switch to Chinese.
4. Set language to Japanese.
5. Confirm tab titles and screen labels switch to Japanese.
6. Set language to English.
7. Confirm tab titles and screen labels switch to English.

### Dark Mode Review Safety

1. Set simulator appearance to Dark.
2. Launch the app.
3. Confirm the app remains in light mode.
4. Confirm text fields, placeholders, disabled buttons, and settings rows remain readable on light backgrounds.

### Settings Links

1. Open Settings.
2. Confirm the screen does not display raw URL, email address, or Bundle ID.
3. Tap Privacy Policy and confirm Safari opens the privacy page.
4. Tap Support and confirm Safari opens the support page.
5. Tap Contact Support and confirm Mail opens a draft.

## App Store Configuration Tests

1. Run `plutil -lint FormulaPad/Resources/Info.plist`.
2. Confirm `ITSAppUsesNonExemptEncryption` is `false`.
3. Confirm target build settings use `INFOPLIST_FILE = FormulaPad/Resources/Info.plist`.
4. Confirm `TARGETED_DEVICE_FAMILY = 1`.
5. Confirm app icon is 1024x1024 and `hasAlpha: no`.

