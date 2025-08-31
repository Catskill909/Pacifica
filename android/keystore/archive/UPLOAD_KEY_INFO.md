# KPFT Upload Key Information

## CRITICAL: Save this information securely!

**App Details:**
- App Name: KPFT
- Package Name: org.kpft.radio
- Keystore Alias: upload

**Keystore Details:**
- Keystore File: upload-keystore.jks
- Keystore Password: kpft2024secure
- Key Password: kpft2024secure
- Key Alias: upload
- Validity: 10000 days (~27 years)

**Certificate Information:**
- Algorithm: RSA
- Key Size: 2048 bits
- Organization: KPFT
- Organizational Unit: Development
- City: Houston
- State: Texas
- Country: US

**Important Notes:**
1. **BACKUP THIS KEYSTORE**: Store the .jks file and passwords in multiple secure locations
2. **NEVER LOSE THIS**: If you lose the keystore, you cannot update the app on Google Play
3. **KEEP PASSWORDS SECURE**: Store passwords in a password manager
4. **DO NOT COMMIT TO GIT**: Never add keystore files to version control

**Google Play Console Setup:**
- When uploading to Google Play Console for the first time, Google will manage app signing
- You upload the APK/AAB signed with this upload key
- Google re-signs with their own key for distribution
- This upload key is only used for uploading to Google Play Console