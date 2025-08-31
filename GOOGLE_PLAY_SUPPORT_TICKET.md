# Assistance Request: Puzzling Signing Key Issue on a New Developer Account

Hello Google Play Support Team,

We're hoping you can help us with a confusing signing key issue we're facing on a brand new developer account. We're trying to upload our first app for the KPFT Radio station, but we're running into a persistent error.

### The Situation:

- **Our Account**: We are using a brand new developer account for "KPFT Radio (Pacifica Foundation)", created on August 31, 2025. We have never uploaded any apps or drafts to this account.
- **The Error**: When we try to upload our app bundle, we receive an error stating that it's signed with the wrong key. The console expects a certificate with the fingerprint: `SHA1: 41:2B:E6:C3:80:E4:B8:29:3F:D3:F8:03:AA:FC:C5:BD:90:E1:FF:1E`.
- **Our Certificate**: We have generated a completely new, clean certificate for our app, which has the fingerprint: `SHA1: 25:F8:C3:C9:F0:DA:80:FC:E5:C5:54:F9:B7:91:A6:49:B9:0B:41:CB`.

### Our Puzzle:

We're puzzled because a brand new account shouldn't have a pre-existing requirement for a specific signing key.

Through our investigation, we found that the certificate Google is asking for (`41:2B:...`) seems to be associated with a different app, "payphone," which is managed under a separate developer account that we also have access to. It appears there might be some crossed wires in the system, linking our new KPFT Radio account to a certificate from another project.

We've tried all the standard troubleshooting steps (clearing caches, generating new keys, using different package names), but the error remains the same. This leads us to believe the issue might be on the platform side.

### How You Can Help:

Could you please investigate why our new KPFT Radio account is requiring this specific, unrelated certificate? We would be very grateful if you could help de-link this requirement so we can proceed with our first app upload.

Thank you for your time and assistance!

Best regards,
The Pacifica Developer Team
