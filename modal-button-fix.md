# Modal button failure on Android tablets — Root cause and fix (no code yet)

## Summary
- The red action buttons in the info modal (opened via the top-right info icon) do not open an external browser on at least one Samsung tablet.
- The same buttons work on a Samsung phone.
- The social icons at the bottom of the modal work on both devices.

## Where this is implemented
- Buttons: `lib/sheet.dart` → `RadioSheet.buildSheet()` uses `_launchURL()` which performs `canLaunchUrl()` and then `launchUrl(..., mode: LaunchMode.externalApplication)`.
- Social icons: `lib/social.dart` → `SocialIcon._launchURL()` calls `launchUrl()` directly (no `canLaunchUrl()` gate) and then dismisses the sheet.

## Root cause (Android 11+ package visibility)
- On Android 11 (API 30) and above, apps must declare “package visibility” for implicit intent queries (like ACTION_VIEW for `http/https`) using a `<queries>` block in `AndroidManifest.xml`.
- The `url_launcher` plugin’s `canLaunchUrl()` internally performs a resolve/query to check if an activity is available. Without the `<queries>` declarations, that resolve returns no matches on some devices (notably certain tablets), making `canLaunchUrl()` return `false`.
- In our red-button flow (`lib/sheet.dart`), we only call `launchUrl()` if `canLaunchUrl()` is `true`. On the affected tablets, `canLaunchUrl()` is `false`, so nothing happens.
- The social icons don’t use `canLaunchUrl()`; they call `launchUrl()` directly. That’s why they work on the same tablet without additional manifest entries.

## Why phone works while tablet doesn’t
- Different OEM builds and default browser packages can cause `PackageManager` queries to behave differently when no `<queries>` are declared. Some phones still resolve successfully; some tablets do not. This produces the observed discrepancy.

## Fix options (choose one, optionally do both)

1) Prefer: Remove the `canLaunchUrl()` gate for the red buttons and call `launchUrl()` directly.
- Rationale: This matches the working pattern used by the social icons and the `url_launcher` guidance that `canLaunchUrl()` is not always necessary for common `http/https` intents.
- Behavior: Attempt to open; if `launchUrl()` returns `false`, show a user-facing message (e.g., SnackBar). This avoids a silent no-op.
- Scope: App-side code change only in `lib/sheet.dart`.

2) Add `<queries>` to `android/app/src/main/AndroidManifest.xml`.
- Rationale: Enables `canLaunchUrl()` to return `true` on Android 11+ for `http`, `https`, and `mailto` (if needed), restoring the pre-Android-11 behavior of resolve checks.
- Suggested entries:
  - ACTION_VIEW for `http`
  - ACTION_VIEW for `https`
  - ACTION_SENDTO for `mailto` (optional but recommended if we keep email links)
- Scope: Android manifest change, no Dart behavior changes required.

## Recommended approach
- Implement Option 1 immediately for reliability parity with the working social icons.
- Additionally implement Option 2 to keep `canLaunchUrl()` viable across devices if we still want to use it elsewhere (defense-in-depth).

## Implementation plan (no code in this doc)
- `lib/sheet.dart`: Update `_launchURL()` usage for the red buttons to call `launchUrl(uri, mode: LaunchMode.externalApplication)` directly and handle the boolean result. Remove or bypass `canLaunchUrl()` for `http/https`.
- `android/app/src/main/AndroidManifest.xml`: Add a `<queries>` section for ACTION_VIEW (`http`, `https`) and ACTION_SENDTO (`mailto`).

## Validation checklist
- On the Samsung tablet, each red button opens the target site in the external browser.
- On the Samsung phone, behavior remains unchanged (still opens externally).
- Social icons remain functional.
- Donate link opens externally (as per product requirement).
- No runtime exceptions when pressing buttons (even if no browser is available, we handle `false` from `launchUrl`).

## Separate UI spacing note (to address later)
- The social icon row is visually too close to the red button grid on tablets. After the functional fix above, we’ll adjust spacing (likely increasing bottom padding on the grid or top padding on `SocialIcons` for tablet breakpoints) without altering any other modal behavior.
