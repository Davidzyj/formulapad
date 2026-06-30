# User Paths And Acceptance Criteria

This document is the implementation contract for V1. A feature is complete only when the path has a clear entry point, the operation works, state is saved where expected, and returning to the screen gives visible feedback.

## Path 1: Calculate With Natural Input

1. User opens the app and lands on the Calculate tab.
2. User enters `20000 * (1 + 0.035)^3`.
3. User taps the calculate button or submits from the keyboard.
4. The result is shown immediately.
5. The expression and result are saved into history.
6. User switches to History and sees the new item.
7. User taps the history item and returns to Calculate with the expression restored.

Acceptance:
- The Calculate tab is the first visible screen.
- Decimal keyboard has a Done path.
- Invalid input shows a readable localized error.
- Valid calculation updates result, appends history, and refreshes UI.
- History mutations are published by replacing arrays or otherwise triggering SwiftUI refresh.

## Path 2: Use Scientific Functions

1. User opens Calculate.
2. User inserts functions such as `sin(45)`, `sqrt(144)`, `log(100)`, `pi`, or `e`.
3. User toggles degree/radian mode.
4. User calculates and sees the result.

Acceptance:
- Scientific buttons insert usable formula text.
- Degree/radian state changes trigonometric output.
- State is visible and localized.
- Result is saved to history.

## Path 3: Save A Calculation As A Note

1. User calculates an expression.
2. User taps Save Note.
3. User enters a title and optional remarks, then selects a category.
4. User saves.
5. User returns to Notes and sees the saved note.
6. User opens the note, edits the remark or favorite status, and saves.

Acceptance:
- Save Note is disabled until there is a valid result.
- Title, category, remarks, expression, result, favorite status, and timestamp persist locally.
- Returning to Notes shows the updated note without relaunching.
- Empty title is handled with a localized validation message.

## Path 4: Reuse A Template

1. User opens Templates.
2. User chooses a template such as compound interest or discount.
3. User fills required fields.
4. User taps Calculate.
5. User sees a result and an explanation.
6. User saves the output to history and can optionally save it as a note.

Acceptance:
- Every visible template has working fields and calculation logic.
- Numeric fields use decimal keyboard with a toolbar Done button.
- Result and explanation are localized.
- Saving creates a history item or note visible in the relevant tab.

## Path 5: Convert Units

1. User opens Convert.
2. User chooses a category, source unit, target unit, and value.
3. User sees a converted value.
4. User taps Save to History.
5. User sees the conversion in History.

Acceptance:
- Switching category updates units and clears impossible selections.
- Conversion works for length, weight, area, volume, temperature, time, and speed.
- Save feedback is visible.
- No stale dictionary/array updates leave the UI unchanged.

## Path 6: Plot A Function

1. Pro user opens Plot.
2. User enters `x^2` or `sin(x)`.
3. User taps Plot.
4. User sees a readable curve.
5. User saves the expression to history.

Acceptance:
- Free user sees a Pro gate with a clear one-time purchase entry.
- Pro user can generate at least quadratic and sine/cosine curves.
- Plot state persists while switching tabs.
- Invalid formula shows a localized error.

## Path 7: Unlock Pro

1. User opens Settings or a Pro-gated feature.
2. User taps Upgrade to Pro.
3. App loads the one-time purchase product.
4. User can buy or restore.
5. After successful transaction, Pro-gated UI unlocks immediately.

Acceptance:
- Purchase and restore buttons are clear.
- Product unavailable state is readable and does not crash.
- Pro entitlement is stored locally and refreshed from StoreKit transactions.
- No subscription copy is shown.

## Path 8: Open Privacy And Support

1. User opens Settings.
2. User taps Privacy Policy or Support.
3. The app opens the relevant GitHub Pages URL in Safari.

Acceptance:
- Settings does not display raw email address, raw support URL, privacy URL, or Bundle ID.
- External pages support English, Simplified Chinese, and Japanese.
- The app only opens these pages after a user tap.

