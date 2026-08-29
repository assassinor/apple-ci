# Credential and rotation runbook

## Ownership and storage

- Match repository: private `assassinor/apple-signing`, branch
  `team-566UG6DQ7E`.
- Match writes: one designated writer only, currently M2. CI and M1 always use
  `readonly: true`.
- App Store Connect: one dedicated Team API key with App Manager role.
- GitHub Actions: one read-only deploy key for the Match repository.
- Plaintext `.p8` and `.p12` files are transient and must be deleted after
  importing or secret upload. Keep recoverable copies only in an approved secret
  manager or the macOS Keychain.

## Designated Match writer

“M2 only” is a local operating policy, not a technical restriction imposed by
Apple, GitHub, Fastlane, or Match. A single writer prevents concurrent
certificate/profile changes, accidental credential drift, and a wider set of
machines holding write-capable recovery material. M2 currently owns that role
because it holds the recovery Keychain items and was used to initialize Match.

The role is transferable. Before a new Mac becomes the writer, restore the
recovery items, verify both Developer ID and App Store identities from Match in
a fresh temporary Keychain, confirm the new Mac can perform an authorized Match
write, and make the former writer readonly or remove its write access. Never
operate two designated writers concurrently.

## Keychain recovery sources

| GitHub secret | Keychain service | Account |
| --- | --- | --- |
| `APPLE_ASC_KEY_ID` | `apple-release-asc-key-id` | `566UG6DQ7E` |
| `APPLE_ASC_ISSUER_ID` | `apple-release-asc-issuer-id` | `566UG6DQ7E` |
| `APPLE_ASC_PRIVATE_KEY_BASE64` | `apple-release-asc-private-key-base64` | the current ASC Key ID |
| `APPLE_MATCH_PASSWORD` | `apple-release-match-password` | `566UG6DQ7E` |
| `APPLE_MATCH_GIT_PRIVATE_KEY` | `apple-release-match-git-private-key` | `readonly-ci` |

GitHub never exposes secret values after they are stored. Existing workflows
continue running without the management Mac, but a new private repository or a
credential rotation needs the recovery sources above.

All five current entries are generic passwords in the file-based
`~/Library/Keychains/login.keychain-db`. Although iCloud Passwords and Keychain
is enabled on M2, these entries were not created with explicit iCloud
synchronization. Do not assume they will appear on a replacement Mac. Restore
them from an independently verified recovery copy before transferring the
writer role. If any item is absent, stop rather than creating an unplanned
replacement.

## Initial bootstrap

1. Create the Team API key in App Store Connect and download its `.p8` once.
2. Create a Developer ID Application certificate and pair it with its private
   key. For Match compatibility on current macOS runners, store imported RSA
   private keys as traditional PKCS#1 PEM even though Match uses a `.p12`
   filename.
3. Import an Apple Distribution identity in the same format. If an existing
   login-keychain identity cannot be exported because the old keychain password
   is unavailable, create a dedicated CI Distribution certificate and leave the
   old certificate valid until its consumers have been audited.
4. On the designated writer (currently M2), initialize Match and import both
   identities/profiles into the fixed branch using a strong `MATCH_PASSWORD`.
5. Verify a fresh temporary keychain can restore both identities using Match in
   readonly mode.
6. Add the five organization secrets, granting access only to onboarded
   repositories. GitHub Free organizations do not expose organization secrets
   to private repositories; use equivalent repository-level secrets for those
   repositories until the organization is upgraded.
7. Delete transient plaintext files.

Do not revoke an old signing certificate automatically: already distributed
software may depend on it. Revoke an old API key only after an inventory proves
that no other automation uses it and the replacement has completed a canary.

## Repository controls

The public `apple-ci` repository uses active default-branch and release-tag
rulesets, secret scanning, and push protection. Keep `apple-signing` private.
On the current GitHub plan, rulesets and secret scanning are unavailable for
that private personal repository; compensate with encrypted-only Match assets,
single-writer operation, an M1 push URL that is deliberately disabled, and a
read-only CI deploy key. Enable the native controls after upgrading the account
plan.

## Rotation

Create the replacement first, import and verify it in Match, update every
organization- or repository-level secret destination, run non-publishing
canaries, then retire the old credential.
Record the key ID, certificate expiry, verification run URLs, and retirement
date without recording secret values.
