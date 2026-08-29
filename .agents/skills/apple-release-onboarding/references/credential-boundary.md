# Credential boundary

- Match writes are allowed only on the M2 machine. M1 and CI are readonly.
- The private Match repository is `assassinor/apple-signing`, fixed branch
  `team-566UG6DQ7E`.
- Use a dedicated App Store Connect Team API key and a Match-only read deploy
  key. Store their values in organization secrets scoped to selected repos.
- Decode P8/P12/deploy-key material only into permission-restricted temporary
  files and remove them in an ensure/always cleanup.
- Do not revoke certificates automatically. Retire an API key only after usage
  inventory and a successful replacement canary.
- App Store Connect app records, agreements, managed capabilities, and Apple
  website credential creation require an explicit manual checkpoint.
- Never use `secrets: inherit` across `omzcj` and `oh-my-app`.
