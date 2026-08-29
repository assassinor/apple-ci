# Credential boundary

- Match is readonly by default on every local machine and in CI.
- A write may run on any trusted Mac after the required management credentials
  have been restored from the approved recovery store. Write access is an
  explicit, short-lived session, not a permanent machine role.
- Never run two Match write sessions concurrently. Before writing, confirm the
  fixed branch is clean and current and that no other session is active. After
  the normal push, verify readonly recovery in a fresh temporary Keychain,
  clear the write-session flag, and remove transient credentials.
- CI always uses the read-only deploy key and can never start a write session.
- The private Match repository is `assassinor/apple-signing`, fixed branch
  `team-566UG6DQ7E`.
- Use a dedicated App Store Connect Team API key and a Match-only read deploy
  key. Store their values in organization secrets scoped to selected repos.
  GitHub Free organizations do not expose organization secrets to private
  repositories, so use equivalent repository-level secrets in that case.
- When importing an RSA private key into Match, encode it as traditional
  PKCS#1 PEM under Match's `.p12` filename. Current macOS runners reject PKCS#8
  PEM when Fastlane imports a file with that extension.
- Decode P8/P12/deploy-key material only into permission-restricted temporary
  files and remove them in an ensure/always cleanup.
- Do not revoke certificates automatically. Retire an API key only after usage
  inventory and a successful replacement canary.
- App Store Connect app records, agreements, managed capabilities, and Apple
  website credential creation require an explicit manual checkpoint.
- Never use `secrets: inherit` across `omzcj` and `oh-my-app`.

## Local Keychain cache convention

The authoritative recovery copy of these values must live in an approved secret
manager or encrypted offline backup. A trusted Mac may cache them as generic
password items using this convention. Read them only when a new private
repository needs repository-level secrets; never print them or place them in a
command transcript.

| GitHub secret | Keychain service | Account |
| --- | --- | --- |
| `APPLE_ASC_KEY_ID` | `apple-release-asc-key-id` | `566UG6DQ7E` |
| `APPLE_ASC_ISSUER_ID` | `apple-release-asc-issuer-id` | `566UG6DQ7E` |
| `APPLE_ASC_PRIVATE_KEY_BASE64` | `apple-release-asc-private-key-base64` | the current ASC Key ID |
| `APPLE_MATCH_PASSWORD` | `apple-release-match-password` | `566UG6DQ7E` |
| `APPLE_MATCH_GIT_PRIVATE_KEY` | `apple-release-match-git-private-key` | `readonly-ci` |

A file-based `login.keychain-db` is only a local operational cache. Do not assume
that it synchronizes through iCloud or treat it as the sole recovery source. If
an item is missing, stop and restore it from the approved recovery store.
