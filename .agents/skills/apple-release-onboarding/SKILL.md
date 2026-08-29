---
name: apple-release-onboarding
description: Connect an existing macOS or iOS app to the shared assassinor/apple-ci Fastlane, Match, and GitHub Actions release system. Use only when explicitly invoked for release onboarding; do not create application source code or a new Xcode project.
---

# Apple Release Onboarding

Onboard a working local Apple app to Team `566UG6DQ7E` signing and release
automation. Preserve its build behavior; this skill does not scaffold an app.

Read [the onboarding contract](references/onboarding-contract.md) before editing
an app. Read [the credential boundary](references/credential-boundary.md) before
any Apple, Match, GitHub secret, or certificate mutation.

## Workflow

1. Require a clean worktree. Inspect remotes, platform, targets/schemes, Bundle
   IDs, entitlements, versioning, scripts, artifacts, and workflows.
2. Choose macOS Developer ID or iOS TestFlight based on the existing product.
3. Present a read-only plan for Bundle ID/capability, Match, secret-access, and
   repository changes. Confirm owner/name/visibility before creating a remote.
   Check the GitHub organization plan: selected organization secrets are the
   default, but a private repository in a GitHub Free organization must receive
   the same five names as repository-level secrets.
4. Configure secret access without printing values. For a repository that can
   use selected organization secrets, add only its repository ID to each
   secret's access policy. For a GitHub Free private repository, run on the
   trusted Mac that has access to the approved recovery store, verify all five
   documented values, and stream each value directly into the corresponding
   repository secret. A validated local Keychain cache may be used, but it is
   not the recovery authority. If a value is absent, stop; do not create
   replacement credentials or assume that a login Keychain synchronized it.
5. Add the standard app-side Fastlane files and a thin caller workflow. Keep
   project-specific validation, packaging, artifact names, and release notes in
   the app repository.
6. Pin `import_from_git` to an immutable `apple-ci` calendar version and the
   reusable workflow to its corresponding full commit SHA; update both together.
   Require `git tag -s` for publishing; the shared lane must verify GitHub's tag
   signature before accessing Apple credentials.
7. Run local syntax/build checks and an Apple capability plan before applying.
8. Use manual dispatch with publish/upload disabled. Do not remove legacy
   secrets until one real canary succeeds.

Normal onboarding never enables Match writes. Only an explicitly requested
certificate or profile maintenance operation may set
`APPLE_MATCH_WRITE_SESSION=1`, and only for one serialized session on a trusted
Mac. Clear it immediately after the verified operation.

Stop at the documented manual boundary for App Store Connect app records,
agreements, managed capabilities, and one-time Apple credential creation. Never
commit, print, or copy a secret into a command transcript.
