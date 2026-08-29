# Credential and rotation runbook

## Ownership and storage

- Match repository: private `assassinor/apple-signing`, branch
  `team-566UG6DQ7E`.
- Match access: readonly by default everywhere. Writes use one explicit,
  short-lived session at a time on any trusted Mac.
- App Store Connect: one dedicated Team API key with App Manager role.
- GitHub Actions: one read-only deploy key for the Match repository.
- Plaintext `.p8` and `.p12` files are transient and must be deleted after
  importing or secret upload. Keep the authoritative recovery copy in an
  approved secret manager or encrypted offline backup; a macOS Keychain is an
  optional local cache.

## Serialized Match write sessions

All machines and CI use Match in readonly mode by default. The ability to write
belongs to a temporary maintenance session, not to a computer. Any trusted Mac
may start a session after restoring the management credentials from the
approved recovery store.

For each write session:

1. Obtain explicit authorization for the specific certificate or profile
   mutation and confirm no other write session is active.
2. Restore the management values and a separate GitHub credential with write
   access. The CI deploy key is intentionally read-only and cannot be reused.
3. Fetch `team-566UG6DQ7E`; require a clean, fast-forward state. Verify GitHub
   access with a non-mutating dry-run before changing Apple or Match state.
4. Set `APPLE_MATCH_WRITE_SESSION=1` only for the planned Match command. Never
   force-push or perform unrelated certificate/profile changes.
5. Push normally, clear the flag, and verify Developer ID and App Store recovery
   through readonly Match in a fresh temporary Keychain.
6. Run the relevant non-publishing canary and remove all transient plaintext
   credentials.

## Credential recovery and local Keychain cache

| GitHub secret | Keychain service | Account |
| --- | --- | --- |
| `APPLE_ASC_KEY_ID` | `apple-release-asc-key-id` | `566UG6DQ7E` |
| `APPLE_ASC_ISSUER_ID` | `apple-release-asc-issuer-id` | `566UG6DQ7E` |
| `APPLE_ASC_PRIVATE_KEY_BASE64` | `apple-release-asc-private-key-base64` | the current ASC Key ID |
| `APPLE_MATCH_PASSWORD` | `apple-release-match-password` | `566UG6DQ7E` |
| `APPLE_MATCH_GIT_PRIVATE_KEY` | `apple-release-match-git-private-key` | `readonly-ci` |

GitHub never exposes secret values after they are stored. Existing workflows
continue running without a management environment, but a new private repository
or a credential rotation needs an independent recovery copy of the values
above.

The authoritative copy must be maintained in an approved secret manager or
encrypted offline backup and tested by restoring it into a separate temporary
Keychain. A trusted Mac may cache the values as generic passwords in its
file-based `~/Library/Keychains/login.keychain-db`, but that cache must not be
assumed to synchronize through iCloud. If any value is absent, stop rather than
creating an unplanned replacement.

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
4. In an authorized write session, initialize Match and import both
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
readonly-by-default clients, serialized write sessions, and a read-only CI
deploy key. Enable the native controls after upgrading the account plan.

## Rotation

Create the replacement first, import and verify it in Match, update every
organization- or repository-level secret destination, run non-publishing
canaries, then retire the old credential.
Record the key ID, certificate expiry, verification run URLs, and retirement
date without recording secret values.
