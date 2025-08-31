# KPFT Android Keystore Setup

## Overview
This folder contains the keystore configuration for signing the KPFT Android app for Google Play Store release.

## Files in this directory:
- `upload-keystore.jks` - The actual keystore file (DO NOT COMMIT TO GIT)
- `keystore.properties` - Keystore configuration (DO NOT COMMIT TO GIT)
- `keystore.properties.sample` - Template for keystore properties
- `UPLOAD_KEY_INFO.md` - Important keystore information to save
- `KEYSTORE_GENERATION_COMMANDS.md` - Commands used to generate the keystore

## Security Notice
⚠️ **CRITICAL**: Never commit the actual keystore file or keystore.properties to version control!

## Setup Instructions
1. Generate keystore using the commands in `KEYSTORE_GENERATION_COMMANDS.md`
2. Copy `keystore.properties.sample` to `keystore.properties`
3. Fill in the actual values in `keystore.properties`
4. Save keystore information in `UPLOAD_KEY_INFO.md`
5. Add keystore files to `.gitignore`