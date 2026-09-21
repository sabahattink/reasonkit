# TASK-004 Public Fixture

This is a dependency-free Node.js configuration loader. The runtime path is
the public tests, `src/config-loader.js`, `src/config-cache.js`,
`src/profile-source.js`, and `src/env-overrides.js`.

`src/diagnostics.js` is a nearby diagnostic helper and is intentionally not
imported by the loader. Treat it as evidence to check, not as proof that it is
the source of the defect.

The workspace directories contain independent file-backed profiles with the
same profile name. Tests use them to reproduce the observed mix-up.
