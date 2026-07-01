#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

DEVICE_ID="${1:-FC791334-2F7B-48AD-93E2-44DF010891BE}"
LANGUAGE_ARG="${2:-all}"
SCHEME="FormulaPad"
BUNDLE_ID="com.zhouyajie.formulapad"
DERIVED_DATA="$ROOT_DIR/build/ScreenshotDerivedData"
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
if [[ "$LANGUAGE_ARG" == "all" ]]; then
  LANGUAGES=(zh-Hans en ja)
else
  LANGUAGES=("$LANGUAGE_ARG")
fi

expected_pattern() {
  local language="$1"
  local scenario="$2"
  case "$language:$scenario" in
    zh-Hans:calculate) echo "算记|22174|principal" ;;
    zh-Hans:history) echo "历史|299|22174" ;;
    zh-Hans:notes) echo "数学笔记|复利|折扣" ;;
    zh-Hans:templates) echo "公式模板|复利|22174" ;;
    zh-Hans:convert) echo "单位换算|78.8|摄氏度|华氏度" ;;
    zh-Hans:plot) echo "函数图像|x\\^2|图像" ;;
    en:calculate) echo "FormulaPad|22174|principal" ;;
    en:history) echo "History|299|22174" ;;
    en:notes) echo "Math Notes|Compound|Discount" ;;
    en:templates) echo "Templates|Compound Interest|22174" ;;
    en:convert) echo "Unit Converter|78.8|Celsius|Fahrenheit" ;;
    en:plot) echo "Function Plot|x\\^2|Plot" ;;
    ja:calculate) echo "数式メモ|22174|principal" ;;
    ja:history) echo "履歴|299|22174" ;;
    ja:notes) echo "数式メモ|複利|割引" ;;
    ja:templates) echo "数式テンプレート|複利|22174" ;;
    ja:convert) echo "単位換算|78.8|摂氏|華氏" ;;
    ja:plot) echo "関数グラフ|描画|×\\^2|x -10" ;;
    *) echo "22174|78.8|x\\^2" ;;
  esac
}

mkdir -p "$ROOT_DIR/build"

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

for language in "${LANGUAGES[@]}"; do
  OUT_DIR="$ROOT_DIR/screenshots/6.5/$language"
  mkdir -p "$OUT_DIR"
  rm -f "$OUT_DIR"/*.png "$OUT_DIR"/*.txt

  echo "Capturing language $language"
  for index in "${!SCENARIOS[@]}"; do
    scenario="${SCENARIOS[$index]}"
    filename="${FILENAMES[$index]}"
    expected="$(expected_pattern "$language" "$scenario")"
    output="$OUT_DIR/$filename"
    raw_output="$OUT_DIR/raw-$filename"
    ocr_output="$OUT_DIR/${filename%.png}.ocr.txt"

    echo "Capturing $language/$scenario -> $filename"
    xcrun simctl terminate "$DEVICE_ID" "$BUNDLE_ID" >/dev/null 2>&1 || true
    SIMCTL_CHILD_FORMULAPAD_SCREENSHOT_MODE=1 \
    SIMCTL_CHILD_FORMULAPAD_SCREENSHOT_LANGUAGE="$language" \
    SIMCTL_CHILD_FORMULAPAD_SCREENSHOT_SCREEN="$scenario" \
    SIMCTL_CHILD_OS_ACTIVITY_MODE=disable \
      xcrun simctl launch "$DEVICE_ID" "$BUNDLE_ID" >/dev/null

    passed=0
    for attempt in 1 2 3 4 5 6 7 8; do
      sleep 1.5
      xcrun simctl io "$DEVICE_ID" screenshot "$raw_output" >/dev/null
      /usr/bin/swift "$ROOT_DIR/scripts/flatten_png.swift" "$raw_output" "$output"
      rm -f "$raw_output"

      dimensions="$(sips -g pixelWidth -g pixelHeight "$output" | awk '/pixelWidth/{w=$2} /pixelHeight/{h=$2} END{print w "x" h}')"
      if [[ "$dimensions" != "$EXPECTED_SIZE" ]]; then
        echo "Unexpected screenshot size for $language/$filename: $dimensions, expected $EXPECTED_SIZE" >&2
        exit 1
      fi

      alpha="$(sips -g hasAlpha "$output" | awk '/hasAlpha/{print $2}')"
      if [[ "$alpha" != "no" ]]; then
        echo "Screenshot still has alpha for $language/$filename" >&2
        exit 1
      fi

      /usr/bin/swift "$ROOT_DIR/scripts/ocr_screenshot.swift" "$output" > "$ocr_output"
      if grep -Eiq "$expected" "$ocr_output"; then
        passed=1
        break
      fi
      echo "Waiting for $language/$scenario to render; OCR attempt $attempt did not match."
    done

    if [[ "$passed" != "1" ]]; then
      echo "OCR check failed for $language/$filename; expected pattern: $expected" >&2
      echo "OCR output:" >&2
      sed -n '1,80p' "$ocr_output" >&2
      exit 1
    fi
  done

  /usr/bin/swift "$ROOT_DIR/scripts/make_contact_sheet.swift" "$OUT_DIR" "$OUT_DIR/contact-sheet.png" "${FILENAMES[@]}" >/dev/null
done

echo "Done. Screenshots:"
for language in "${LANGUAGES[@]}"; do
  OUT_DIR="$ROOT_DIR/screenshots/6.5/$language"
  for filename in "${FILENAMES[@]}"; do
    dimensions="$(sips -g pixelWidth -g pixelHeight -g hasAlpha "$OUT_DIR/$filename" | awk '/pixelWidth/{w=$2} /pixelHeight/{h=$2} /hasAlpha/{a=$2} END{print w "x" h ", alpha=" a}')"
    echo "$OUT_DIR/$filename $dimensions"
  done
  echo "$OUT_DIR/contact-sheet.png"
done
