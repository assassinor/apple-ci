# Apple CI

Shared, secret-free signing and release automation for Apple apps owned by
`omzcj` and `oh-my-app`.

This public repository contains:

- reusable GitHub Actions workflows for Developer ID and TestFlight releases;
- shared Fastlane lanes imported by each app repository;
- an idempotent App Store Connect Bundle ID/capability helper;
- the explicit `$apple-release-onboarding` Codex Skill and its operator guide.

Signing assets are stored separately in the private
`assassinor/apple-signing` Match repository. Never commit certificates,
provisioning profiles, API keys, passwords, or deploy keys here.

Start with [the onboarding guide](docs/onboarding.md). Credential bootstrap and
rotation are documented in [the credential runbook](docs/credentials.md).
