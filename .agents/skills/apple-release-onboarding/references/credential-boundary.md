# Credential boundary

- Match has exactly one designated writer at a time; that role is currently
  assigned to M2. This is an operational safety boundary, not an Apple,
  Fastlane, or hardware requirement. M1 and CI are readonly.
- Transfer the writer role only after the replacement Mac has restored the
  recovery items below, passed a fresh temporary-keychain Match verification,
  and the previous writer has been removed or returned to readonly operation.
- The private Match repository is `assassinor/apple-signing`, fixed branch
  `team-566UG6DQ7E`.
- Use a dedicated App Store Connect Team API key and a Match-only read deploy
  key. Store their values in organization secrets scoped to selected repos.
  GitHub Free organizations do not expose organization secrets to private
  repositories, so use equivalent repository-level secrets in that case.
- When importing an RSA private key into Match on M2, encode it as traditional
  PKCS#1 PEM under Match's `.p12` filename. Current macOS runners reject PKCS#8
  PEM when Fastlane imports a file with that extension.
- Decode P8/P12/deploy-key material only into permission-restricted temporary
  files and remove them in an ensure/always cleanup.
- Do not revoke certificates automatically. Retire an API key only after usage
  inventory and a successful replacement canary.
- App Store Connect app records, agreements, managed capabilities, and Apple
  website credential creation require an explicit manual checkpoint.
- Never use `secrets: inherit` across `omzcj` and `oh-my-app`.

## Credential-management Keychain items

These are the current local recovery sources. Read values only when a new
private repository needs repository-level secrets; never print them or place
them in a command transcript.

| GitHub secret | Keychain service | Account |
| --- | --- | --- |
| `APPLE_ASC_KEY_ID` | `apple-release-asc-key-id` | `566UG6DQ7E` |
| `APPLE_ASC_ISSUER_ID` | `apple-release-asc-issuer-id` | `566UG6DQ7E` |
| `APPLE_ASC_PRIVATE_KEY_BASE64` | `apple-release-asc-private-key-base64` | the current ASC Key ID |
| `APPLE_MATCH_PASSWORD` | `apple-release-match-password` | `566UG6DQ7E` |
| `APPLE_MATCH_GIT_PRIVATE_KEY` | `apple-release-match-git-private-key` | `readonly-ci` |

The current items are in the file-based `login.keychain-db`. iCloud Passwords
and Keychain is enabled on M2, but these items were not created as explicitly
synchronizable data-protection Keychain items. Do not treat iCloud as their
recovery source; if any item is missing, stop and follow the recovery runbook.
