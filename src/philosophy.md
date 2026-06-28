# Philosophy

- **Bazel-native first.** Cross-module workflows are expressible as Bazel
  targets, not out-of-band scripts.
- **Hermetic by default.** Each module either pins its upstream artifact's
  sha256 + extracts deterministically, or vendors a source tarball with the
  same. Host-tool dependencies are limited to OS-provided utilities that don't
  drift.
- **Honest about gaps.** Modules ship at `0.0.x` with explicit "no smoke" labels
  when not yet verified end-to-end. We don't pretend.
- **One thing per module.** Splitting beats coupling.

## Contributing

Each module has its own issues + PRs. For org-wide coordination (cross-module
bumps, registry-tier moves, agent dispatch), **botnoc** — the bot-driven Network
Operations Center — is the entry point. botnoc renders the module catalog above
and orchestrates work across the constellation.
