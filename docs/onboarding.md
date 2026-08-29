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
workflow. Import the shared Fastfile at an immutable `apple-ci` semantic version
and call the reusable workflow at the corresponding full commit SHA.

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

## Validate and roll out

Run capability reconciliation without `--apply` first. Use a manual workflow
dispatch with publishing/upload disabled, then perform one real canary. Remove
legacy repository P12/profile/API secrets only after the canary succeeds.

Creating an App Store Connect app record, accepting agreements, requesting a
managed capability, and creating new Apple credentials remain explicit manual
checkpoints.
