# URGENT: PACIFICA KEYSTORE SEARCH

## GOOGLE PLAY EXPECTS THIS CERTIFICATE:
SHA1: 41:2B:E6:C3:80:E4:B8:29:3F:D3:F8:03:AA:FC:C5:BD:90:E1:FF:1E

## SEARCH LOCATIONS:
1. **Pacifica shared drives/repositories**
2. **Previous developer workstations**
3. **Shared keystore storage**
4. **Other Pacifica app projects**
5. **Backup systems**

## SEARCH COMMANDS:
```bash
# Search for all keystores
find /Users -name "*.jks" -o -name "*.keystore" 2>/dev/null

# Check each keystore for the fingerprint
keytool -list -v -keystore KEYSTORE_FILE.jks -storepass PASSWORD | grep SHA1
```

## TARGET FINGERPRINT:
41:2B:E6:C3:80:E4:B8:29:3F:D3:F8:03:AA:FC:C5:BD:90:E1:FF:1E

## QUESTIONS FOR PACIFICA TEAM:
- Who created the Google Play Console account?
- Any previous app uploads (even drafts)?
- Shared keystores or development resources?
- Connection to starkey.digital developers?
