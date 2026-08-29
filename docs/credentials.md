# Credential and rotation runbook

## Ownership and storage

- Match repository: private `assassinor/apple-signing`, branch
  `team-566UG6DQ7E`.
- Match writes: M2 only. CI and M1 always use `readonly: true`.
- App Store Connect: one dedicated Team API key with App Manager role.
- GitHub Actions: one read-only deploy key for the Match repository.
- Plaintext `.p8` and `.p12` files are transient and must be deleted after
  importing or secret upload. Keep recoverable copies only in an approved secret
  manager or the macOS Keychain.

## Initial bootstrap

1. Create the Team API key in App Store Connect and download its `.p8` once.
2. Create a Developer ID Application certificate and export it with its private
   key as a password-protected P12.
3. Export the existing Apple Distribution identity as a password-protected P12.
4. On M2, initialize Match and import both identities/profiles into the fixed
   branch using a strong `MATCH_PASSWORD`.
5. Verify a fresh temporary keychain can restore both identities using Match in
   readonly mode.
6. Add the five organization secrets to `omzcj` and `oh-my-app`, granting access
   only to onboarded repositories.
7. Delete transient plaintext files.

Do not revoke an old signing certificate automatically: already distributed
software may depend on it. Revoke an old API key only after an inventory proves
that no other automation uses it and the replacement has completed a canary.

## Rotation

Create the replacement first, import and verify it in Match, update both
organizations, run non-publishing canaries, then retire the old credential.
Record the key ID, certificate expiry, verification run URLs, and retirement
date without recording secret values.
