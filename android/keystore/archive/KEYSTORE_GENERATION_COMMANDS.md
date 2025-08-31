# Keystore Generation Commands

## Generate Upload Keystore for Google Play Store

Run this command in the `android/keystore/` directory:

```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# You will be prompted for:
# - Keystore password (choose a strong password)
# - Key password (can be same as keystore password)
# - Your name and organization details
```

## Alternative using Android Studio's keytool:
```bash
# If keytool is not in PATH, use Android Studio's version:
~/Library/Android/sdk/build-tools/34.0.0/keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

## Information to provide when prompted:
- **What is your first and last name?**: KPFT Pacifica
- **What is the name of your organizational unit?**: Development
- **What is the name of your organization?**: KPFT
- **What is the name of your City or Locality?**: Houston
- **What is the name of your State or Province?**: Texas
- **What is the two-letter country code for this unit?**: US

## After generation:
1. Save all passwords securely
2. Update `keystore.properties` with the correct paths and passwords
3. Update `UPLOAD_KEY_INFO.md` with keystore details
4. **NEVER commit the .jks file or keystore.properties to git**
