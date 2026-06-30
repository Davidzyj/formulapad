#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

DEVICE_ID="${1:-FC791334-2F7B-48AD-93E2-44DF010891BE}"
SCHEME="FormulaPad"
BUNDLE_ID="com.zhouyajie.formulapad"
DERIVED_DATA="$ROOT_DIR/build/ScreenshotDerivedData"
OUT_DIR="$ROOT_DIR/screenshots/6.5/zh-Hans"
BUILD_LOG="$ROOT_DIR/build/screenshot-build.log"
EXPECTED_SIZE="1242x2688"

SCENARIOS=(calculate history notes templates convert plot)
FILENAMES=(
  01-calculate.png
  02-history.png
  03-notes.png
  04-templates.png
  05-convert.png
  06-plot.png
)
EXPECTED_PATTERNS=(
  "算记|22174|principal"
  "历史|299|22174"
  "数学笔记|复利|折扣"
  "公式模板|复利|22174"
  "单位换算|78.8|摄氏度|华氏度"
  "函数图像|x\\^2|waveform|图像"
)

mkdir -p "$OUT_DIR" "$ROOT_DIR/build"
rm -f "$OUT_DIR"/*.png "$OUT_DIR"/*.txt

echo "Building $SCHEME for $DEVICE_ID"
xcodebuild \
  -project FormulaPad.xcodeproj \
  -scheme "$SCHEME" \
  -configuration Debug \
  -destination "platform=iOS Simulator,id=$DEVICE_ID" \
  -derivedDataPath "$DERIVED_DATA" \
  build > "$BUILD_LOG"

APP_PATH="$DERIVED_DATA/Build/Products/Debug-iphonesimulator/FormulaPad.app"
if [[ ! -d "$APP_PATH" ]]; then
  echo "Built app not found at $APP_PATH" >&2
  exit 1
fi

xcrun simctl bootstatus "$DEVICE_ID" -b >/dev/null
xcrun simctl uninstall "$DEVICE_ID" "$BUNDLE_ID" >/dev/null 2>&1 || true
xcrun simctl install "$DEVICE_ID" "$APP_PATH" >/dev/null

for index in "${!SCENARIOS[@]}"; do
  scenario="${SCENARIOS[$index]}"
  filename="${FILENAMES[$index]}"
  expected="${EXPECTED_PATTERNS[$index]}"
  output="$OUT_DIR/$filename"
  raw_output="$OUT_DIR/raw-$filename"
  ocr_output="$OUT_DIR/${filename%.png}.ocr.txt"

  echo "Capturing $scenario -> $filename"
  xcrun simctl terminate "$DEVICE_ID" "$BUNDLE_ID" >/dev/null 2>&1 || true
  SIMCTL_CHILD_FORMULAPAD_SCREENSHOT_MODE=1 \
  SIMCTL_CHILD_FORMULAPAD_SCREENSHOT_SCREEN="$scenario" \
  SIMCTL_CHILD_OS_ACTIVITY_MODE=disable \
    xcrun simctl launch "$DEVICE_ID" "$BUNDLE_ID" >/dev/null

  sleep 2.8
  xcrun simctl io "$DEVICE_ID" screenshot "$raw_output" >/dev/null
  /usr/bin/swift "$ROOT_DIR/scripts/flatten_png.swift" "$raw_output" "$output"
  rm -f "$raw_output"

  dimensions="$(sips -g pixelWidth -g pixelHeight "$output" | awk '/pixelWidth/{w=$2} /pixelHeight/{h=$2} END{print w "x" h}')"
  if [[ "$dimensions" != "$EXPECTED_SIZE" ]]; then
    echo "Unexpected screenshot size for $filename: $dimensions, expected $EXPECTED_SIZE" >&2
    exit 1
  fi

  alpha="$(sips -g hasAlpha "$output" | awk '/hasAlpha/{print $2}')"
  if [[ "$alpha" != "no" ]]; then
    echo "Screenshot still has alpha for $filename" >&2
    exit 1
  fi

  /usr/bin/swift "$ROOT_DIR/scripts/ocr_screenshot.swift" "$output" > "$ocr_output"
  if ! grep -Eiq "$expected" "$ocr_output"; then
    echo "OCR check failed for $filename; expected pattern: $expected" >&2
    echo "OCR output:" >&2
    sed -n '1,80p' "$ocr_output" >&2
    exit 1
  fi
done

/usr/bin/swift "$ROOT_DIR/scripts/make_contact_sheet.swift" "$OUT_DIR" "$OUT_DIR/contact-sheet.png" "${FILENAMES[@]}" >/dev/null

echo "Done. Screenshots:"
for filename in "${FILENAMES[@]}"; do
  dimensions="$(sips -g pixelWidth -g pixelHeight -g hasAlpha "$OUT_DIR/$filename" | awk '/pixelWidth/{w=$2} /pixelHeight/{h=$2} /hasAlpha/{a=$2} END{print w "x" h ", alpha=" a}')"
  echo "$OUT_DIR/$filename $dimensions"
done
echo "$OUT_DIR/contact-sheet.png"
