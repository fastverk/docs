# fastverk

**Agents that behave.**

fastverk puts coding agents to work inside real limits. Each task gets a budget,
a lease on the packages it may change, and a person who signs off. Every change
runs every test it could affect, on remote execution, before anything merges.
It works with a Bazel codebase on GitHub or self-hosted GitLab.

Underneath is a Bazel-native platform: a public module registry (the `rules_*`
constellation, one concern per module), hermetic remote builds with a shared
cache, and the source and network layers that compose on top. These docs cover
how to use it. The product overview is at [fastverk.com](https://fastverk.com).

## Where to go next

- **[The platform](platform.md)** — the products: `fvkit`, the desktop app, the
  brand, and the turnkey AWS install.
- **[The constellation](constellation.md)** — the `rules_*` registry: one module
  per concern, composed into hermetic builds.
- **[Ship vehicles](vehicles.md)** — where each legacy repo and module lives
  now: six git vehicles, independent Bazel names and versions.
- **[Quick start](quickstart.md)** — wire the registry into your own Bazel build.
- **[Agent coordination](agents.md)** — the agent-to-agent tool surface: how a
  fleet of coding agents discovers, claims, hands off, and asks a human.
- **[Philosophy](philosophy.md)** — Bazel-native, hermetic, honest about gaps.
