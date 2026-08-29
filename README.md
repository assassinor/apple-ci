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

## Versioning

Releases use immutable, signed `vYYYY.MM.DD.N` tags. `N` starts at `1` for each
date and is never zero-padded. Historical `v1.0.x` tags remain valid and are not
renamed or moved. App callers pin the shared Fastfile to the calendar tag and
the reusable workflow to its corresponding full commit SHA.
