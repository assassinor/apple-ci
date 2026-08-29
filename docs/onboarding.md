# Existing app onboarding

Use this process when a working local Apple app is ready for GitHub signing and
release automation. It does not create an app or Xcode project.

## Repository defaults

- macOS app: propose `omzcj/<repo>`, public.
- iOS app: propose `oh-my-app/<repo>`, private.
- Confirm the owner, name, and visibility before creating a GitHub repository.
- Apple Developer Team: `566UG6DQ7E`.

## Inspect before changing

1. Require a clean Git worktree and inspect the remote/default branch.
2. Identify the platform, Xcode project/workspace or Swift package, schemes,
   release scripts, Bundle IDs, entitlements, and existing workflows.
3. Select `macos-developer-id.yml` for direct macOS distribution or
   `ios-testflight.yml` for App Store/TestFlight distribution.
4. Preserve project-specific triggers, version rules, packaging, artifact names,
   and release notes.

## Add the app-side contract

Add a locked Fastlane dependency, `fastlane/Appfile`, `fastlane/Matchfile`, a
thin `fastlane/Fastfile`, optional `fastlane/capabilities.yml`, and a caller
workflow. Import the shared Fastfile at an immutable `apple-ci` calendar version
(`vYYYY.MM.DD.N`) and call the reusable workflow at the corresponding full
commit SHA.

Publishing tags must be created with `git tag -s`. The shared lane verifies the
GitHub tag object's cryptographic signature and rejects lightweight, annotated
but unsigned, invalid, or mismatched tags before reading Apple credentials.

Caller workflows explicitly map these standard secrets:

- `APPLE_ASC_KEY_ID`
- `APPLE_ASC_ISSUER_ID`
- `APPLE_ASC_PRIVATE_KEY_BASE64`
- `APPLE_MATCH_PASSWORD`
- `APPLE_MATCH_GIT_PRIVATE_KEY`

Never use `secrets: inherit` across organizations.

Prefer organization secrets with selected-repository access. Before configuring
them, check the organization plan and repository visibility. GitHub Free does
not expose organization secrets to private repositories, so a private app in a
Free organization must use repository-level secrets with the same names.

## Configure secret access for a new repository

For a public `omzcj` repository, do not read or copy secret values. Add the new
repository to the selected-repository policy of each existing organization
secret with the per-repository additive API. Do not replace the existing
selected-repository list. Afterward, verify that all five secrets preserve the
previous repositories and include the new repository.

For a private `oh-my-app` repository while the organization is on GitHub Free,
configure the five names as repository secrets. On any trusted Mac with access
to the approved recovery store, verify all five values documented in the
[credential runbook](credentials.md), then stream each value directly into its
matching GitHub secret without displaying or logging it. A validated Keychain
cache may supply the values. Resolve the ASC private key account from the current
`APPLE_ASC_KEY_ID` so key rotation does not leave a hard-coded Key ID behind.

If any recovery value is missing, stop onboarding. Do not silently create a new
ASC key, Match password, certificate, or deploy key. A local login Keychain is a
cache and must not be assumed to synchronize through iCloud.

Normal app onboarding never enables Match writes. Only an explicitly authorized
certificate/profile maintenance operation may set
`APPLE_MATCH_WRITE_SESSION=1`, and it must clear the flag after the serialized
write session.

## Validate and roll out

Run capability reconciliation without `--apply` first. Use a manual workflow
dispatch with publishing/upload disabled, then perform one real canary. Remove
legacy repository P12/profile/API secrets only after the canary succeeds.

Creating an App Store Connect app record, accepting agreements, requesting a
managed capability, and creating new Apple credentials remain explicit manual
checkpoints.
