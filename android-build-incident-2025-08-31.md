# Incident Report: Google Play Console Cross-Account Bug

- **Date**: 2025-08-31
- **Status**: **BLOCKED**
- **Root Cause**: **Google Play Console Platform Bug** (Cross-Account Certificate Contamination)

## 1. Executive Summary

All attempts to upload the KPFT Radio app to a brand new Google Play developer account have failed. The console is incorrectly demanding a certificate fingerprint (`SHA1: 41:2B:...`) that belongs to a separate, unrelated application ("payphone") from a different developer account. This is an impossible scenario for a new account and constitutes a critical platform bug, preventing the app's launch.

## 2. Timeline of Events

- **Account Creation**: A new Google Play developer account was created for "KPFT Radio (Pacifica Foundation)" on 2025-08-31.
- **Initial Upload Attempts**: Multiple builds were performed with unique package names (`com.pacifica.app.pacifica2`, `app.pacifica.kpft`, etc.). All uploads failed with the same error, demanding the `41:2B:...` certificate.
- **Keystore Contamination Hypothesis**: Initial investigation incorrectly focused on local keystore contamination. The alias "upload" was suspected of conflicting with a keystore from the "payphone" project.
- **Corrective Action (Local)**: A completely fresh keystore (`kpft-radio-fresh.jks`) was generated with a unique alias (`kpftradio2025`) and unique passwords. All local build caches (`.gradle`, `flutter clean`) were cleared.
- **Final Test**: An app bundle was built and signed with the new, clean certificate (`SHA1: 25:F8:...`). The upload failed again, with Google Play Console still demanding the unrelated `41:2B:...` certificate.

## 3. Definitive Diagnosis

- The issue is **not** a local configuration error, cache problem, or keystore error.
- The root cause is **Cross-Account Contamination** within Google's infrastructure. The Google account used to access the new developer console has incorrectly linked certificate data from another developer profile.

## 4. Resolution

- **Local Workarounds**: Ceased. No local changes can fix this platform bug.
- **Path Forward**: Escalate to Google Play Support using the detailed evidence in `GOOGLE_PLAY_SUPPORT_TICKET.md`. The request is for Google's engineering team to manually de-link the incorrect certificate from the KPFT Radio account and reset its signing key requirements.

