# Onboarding contract

Canonical human guide: `docs/onboarding.md` at the root of `assassinor/apple-ci`.

Add to each app:

- `Gemfile` and committed `Gemfile.lock`, with Fastlane locked to the shared
  repository's supported version.
- `fastlane/Appfile` with Bundle ID and Team ID.
- `fastlane/Matchfile` with the private Match URL, branch
  `team-566UG6DQ7E`, identifiers, type, and CI readonly behavior.
- `fastlane/Fastfile` importing the shared Fastfile at an immutable semantic tag.
- Optional `fastlane/capabilities.yml` for standard Apple capabilities.
- A thin workflow invoking the corresponding reusable workflow by full SHA and
  explicitly mapping the five `APPLE_*` organization secrets.

Defaults proposed before confirmation: public `omzcj` for macOS, private
`oh-my-app` for iOS. Preserve an existing repository's owner and visibility.

Run `bundle exec fastlane lanes`, workflow YAML validation, project tests, and a
manual non-publishing workflow. Treat capability configuration as additive: do
not disable an existing capability merely because it is absent from the file.
