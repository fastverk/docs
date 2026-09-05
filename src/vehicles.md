# Ship vehicles

Git repos were collapsed by **ship vehicle**. Bazel module names and
versions were not. Each of the six vehicles carries a `LEDGER.md`
(the provenance record) and CI. Consumers still write
`bazel_dep(name = "…", version = "…")` against the same identities as
before.

**Git repo ≠ Bazel module.** A subtree import does not rename
`module(name = …)` and does not rewrite `module(version = …)`. Imports
used `git subtree add` **without** `--squash`, so source history lives
under the prefix. Source repos were not deleted.

Six of them are now **retired**: the vehicle is the edit surface, the
source remote keeps its history, tags, and published registry versions.
See [Consolidation](consolidation.md) for what that means and which
repos stay live.

## How to find a module

1. Look up the legacy repo (or module name) in the map below.
2. Clone the vehicle. The module is at the listed path.
3. Published identity is that path's `MODULE.bazel` — except
   [`contracts`](https://github.com/fastverk/contracts) and
   [`spec`](https://github.com/fastverk/spec), whose published module is
   the repository root.
4. Tags are per-module `<dir>/vX.Y.Z` (for example `rules_jena/v0.3.3`,
   `forge/v0.0.7`). `spec` keeps root tags `vX.Y.Z`. `contracts` is one
   module at the root.
5. For source SHA, absorbs, and excludes, open that vehicle's
   `LEDGER.md`.

## The six vehicles

| Vehicle | Holds | Layout |
|---|---|---|
| [`tomato-bazel/rules`](https://github.com/tomato-bazel/rules) | public `rules_*` | one directory per module; [LEDGER](https://github.com/tomato-bazel/rules/blob/main/LEDGER.md) |
| [`fastverk/plugin-shell`](https://github.com/fastverk/plugin-shell) | console plugins | one directory per module; private vehicle; [LEDGER](https://github.com/fastverk/plugin-shell/blob/main/LEDGER.md) |
| [`fastverk/contracts`](https://github.com/fastverk/contracts) | public gRPC protos | one module, `fastverk_contracts` `0.0.1`; [LEDGER](https://github.com/fastverk/contracts/blob/main/LEDGER.md) |
| [`fastverk/platform`](https://github.com/fastverk/platform) | gateway / adapter implementations | `forge`, `tracker`, `service-finder`, `wave`; [LEDGER](https://github.com/fastverk/platform/blob/main/LEDGER.md) |
| [`fastverk/desktop`](https://github.com/fastverk/desktop) | desktop / runtime | `fvkit`, `fastverk-app`; [LEDGER](https://github.com/fastverk/desktop/blob/main/LEDGER.md) |
| [`fastverk/spec`](https://github.com/fastverk/spec) | Lean / RDF spine | native (not a sibling-repo subtree); [LEDGER](https://github.com/fastverk/spec/blob/main/LEDGER.md) |

Disposition used in the map:

| Status | Meaning |
|---|---|
| **imported** | directory present; independent Bazel module; subtree history kept |
| **native** | already in `spec`; not subtree-imported from a sibling |
| **consolidated** | proto copied into `fastverk_contracts`; the source module name is **not** redeclared here |
| **absorb** | residue belongs with another imported module; not its own module directory |
| **pending** | listed for a follow-up; not in the tree |

## Non-obvious legacy repos

These do not land as a same-named module directory. Everything else
matches `tomato-bazel/rules_<name>` or `fastverk/<top-level-dir>`.

| Legacy repo | Vehicle | Path | Disposition |
|---|---|---|---|
| [`fastverk/agents`](https://github.com/fastverk/agents) (private) | [`contracts`](https://github.com/fastverk/contracts) | [`proto/agent/v1`](https://github.com/fastverk/contracts/tree/main/proto/agent/v1) | consolidated into `fastverk_contracts` — not published as `fastverk_agents` |
| [`fastverk/plugin-org`](https://github.com/fastverk/plugin-org) | [`plugin-shell`](https://github.com/fastverk/plugin-shell) | `plugin-estate` | **pending absorb** — not an independent imported module |
| [`fastverk/plugin-planning`](https://github.com/fastverk/plugin-planning) | [`platform`](https://github.com/fastverk/platform) | [`wave`](https://github.com/fastverk/platform/tree/main/wave) | **absorb** — not an independent imported module |
| [`fastverk/forge`](https://github.com/fastverk/forge) protos | [`contracts`](https://github.com/fastverk/contracts) | [`proto/forge/v1`](https://github.com/fastverk/contracts/tree/main/proto/forge/v1) | consolidated — not published as `forge` |
| [`fastverk/tracker`](https://github.com/fastverk/tracker) protos | [`contracts`](https://github.com/fastverk/contracts) | [`proto/tracker/v1`](https://github.com/fastverk/contracts/tree/main/proto/tracker/v1) | consolidated — not published as `tracker` |
| [`fastverk/service-finder`](https://github.com/fastverk/service-finder) protos | [`contracts`](https://github.com/fastverk/contracts) | [`proto/fastverk/finder/v1`](https://github.com/fastverk/contracts/tree/main/proto/fastverk/finder/v1) | consolidated — not published as `service_finder` |
| [`fastverk/wave`](https://github.com/fastverk/wave) protos | [`contracts`](https://github.com/fastverk/contracts) | [`proto/wave/v1`](https://github.com/fastverk/contracts/tree/main/proto/wave/v1) | consolidated — not published as `wave` |

Implementation trees for forge / tracker / service-finder / wave still
live under [`platform`](https://github.com/fastverk/platform) as their
own modules (table below). `fastverk/agents` implementation stays in
that private repo.

## tomato-bazel/rules

Fifty imported `rules_*` modules. Tags: `rules_<name>/vX.Y.Z`.

| Legacy repo | Path | `module(name)` | Version |
|---|---|---|---|
| [tomato-bazel/rules_agentic_ide](https://github.com/tomato-bazel/rules_agentic_ide) | [`rules_agentic_ide`](https://github.com/tomato-bazel/rules/tree/main/rules_agentic_ide) | `rules_agentic_ide` | 0.0.4 |
| [tomato-bazel/rules_aip](https://github.com/tomato-bazel/rules_aip) | [`rules_aip`](https://github.com/tomato-bazel/rules/tree/main/rules_aip) | `rules_aip` | 0.3.0 |
| [tomato-bazel/rules_astro](https://github.com/tomato-bazel/rules_astro) | [`rules_astro`](https://github.com/tomato-bazel/rules/tree/main/rules_astro) | `rules_astro` | 0.0.1 |
| [tomato-bazel/rules_autoconf](https://github.com/tomato-bazel/rules_autoconf) | [`rules_autoconf`](https://github.com/tomato-bazel/rules/tree/main/rules_autoconf) | `rules_autoconf` | 0.1.0 |
| [tomato-bazel/rules_beam](https://github.com/tomato-bazel/rules_beam) | [`rules_beam`](https://github.com/tomato-bazel/rules/tree/main/rules_beam) | `rules_beam` | 0.0.2 |
| [tomato-bazel/rules_bibtex](https://github.com/tomato-bazel/rules_bibtex) | [`rules_bibtex`](https://github.com/tomato-bazel/rules/tree/main/rules_bibtex) | `rules_bibtex` | 0.0.6 |
| [tomato-bazel/rules_bun](https://github.com/tomato-bazel/rules_bun) | [`rules_bun`](https://github.com/tomato-bazel/rules/tree/main/rules_bun) | `rules_bun` | 0.4.1 |
| [tomato-bazel/rules_cc_cross](https://github.com/tomato-bazel/rules_cc_cross) | [`rules_cc_cross`](https://github.com/tomato-bazel/rules/tree/main/rules_cc_cross) | `rules_cc_cross` | 0.1.0 |
| [tomato-bazel/rules_cc_host](https://github.com/tomato-bazel/rules_cc_host) | [`rules_cc_host`](https://github.com/tomato-bazel/rules/tree/main/rules_cc_host) | `rules_cc_host` | 0.1.0 |
| [tomato-bazel/rules_chrome](https://github.com/tomato-bazel/rules_chrome) | [`rules_chrome`](https://github.com/tomato-bazel/rules/tree/main/rules_chrome) | `rules_chrome` | 0.1.1 |
| [tomato-bazel/rules_ci](https://github.com/tomato-bazel/rules_ci) | [`rules_ci`](https://github.com/tomato-bazel/rules/tree/main/rules_ci) | `rules_ci` | 0.3.0 |
| [tomato-bazel/rules_cloudformation](https://github.com/tomato-bazel/rules_cloudformation) | [`rules_cloudformation`](https://github.com/tomato-bazel/rules/tree/main/rules_cloudformation) | `rules_cloudformation` | 0.10.0 |
| [tomato-bazel/rules_docker_compose](https://github.com/tomato-bazel/rules_docker_compose) | [`rules_docker_compose`](https://github.com/tomato-bazel/rules/tree/main/rules_docker_compose) | `rules_docker_compose` | 0.2.6 |
| [tomato-bazel/rules_eslint](https://github.com/tomato-bazel/rules_eslint) | [`rules_eslint`](https://github.com/tomato-bazel/rules/tree/main/rules_eslint) | `rules_eslint` | 0.1.0 |
| [tomato-bazel/rules_fastverk_plugin](https://github.com/tomato-bazel/rules_fastverk_plugin) | [`rules_fastverk_plugin`](https://github.com/tomato-bazel/rules/tree/main/rules_fastverk_plugin) | `rules_fastverk_plugin` | 0.0.1 |
| [tomato-bazel/rules_github](https://github.com/tomato-bazel/rules_github) | [`rules_github`](https://github.com/tomato-bazel/rules/tree/main/rules_github) | `rules_github` | 0.1.2 |
| [tomato-bazel/rules_gitlab](https://github.com/tomato-bazel/rules_gitlab) | [`rules_gitlab`](https://github.com/tomato-bazel/rules/tree/main/rules_gitlab) | `rules_gitlab` | 0.3.4 |
| [tomato-bazel/rules_graphviz](https://github.com/tomato-bazel/rules_graphviz) | [`rules_graphviz`](https://github.com/tomato-bazel/rules/tree/main/rules_graphviz) | `rules_graphviz` | 0.2.0 |
| [tomato-bazel/rules_helm](https://github.com/tomato-bazel/rules_helm) | [`rules_helm`](https://github.com/tomato-bazel/rules/tree/main/rules_helm) | `rules_helm` | 0.2.0 |
| [tomato-bazel/rules_huggingface](https://github.com/tomato-bazel/rules_huggingface) | [`rules_huggingface`](https://github.com/tomato-bazel/rules/tree/main/rules_huggingface) | `rules_huggingface` | 0.0.4 |
| [tomato-bazel/rules_jena](https://github.com/tomato-bazel/rules_jena) | [`rules_jena`](https://github.com/tomato-bazel/rules/tree/main/rules_jena) | `rules_jena` | 0.3.2 |
| [tomato-bazel/rules_jsonschema](https://github.com/tomato-bazel/rules_jsonschema) | [`rules_jsonschema`](https://github.com/tomato-bazel/rules/tree/main/rules_jsonschema) | `rules_jsonschema` | 0.4.0 |
| [tomato-bazel/rules_k8s](https://github.com/tomato-bazel/rules_k8s) | [`rules_k8s`](https://github.com/tomato-bazel/rules/tree/main/rules_k8s) | `rules_k8s` | 0.0.3 |
| [tomato-bazel/rules_lang](https://github.com/tomato-bazel/rules_lang) | [`rules_lang`](https://github.com/tomato-bazel/rules/tree/main/rules_lang) | `rules_lang` | 0.5.0 |
| [tomato-bazel/rules_lean](https://github.com/tomato-bazel/rules_lean) | [`rules_lean`](https://github.com/tomato-bazel/rules/tree/main/rules_lean) | `rules_lean` | 0.7.0 |
| [tomato-bazel/rules_lora](https://github.com/tomato-bazel/rules_lora) | [`rules_lora`](https://github.com/tomato-bazel/rules/tree/main/rules_lora) | `rules_lora` | 0.1.4 |
| [tomato-bazel/rules_macvm](https://github.com/tomato-bazel/rules_macvm) | [`rules_macvm`](https://github.com/tomato-bazel/rules/tree/main/rules_macvm) | `rules_macvm` | 0.0.1 |
| [tomato-bazel/rules_markdown](https://github.com/tomato-bazel/rules_markdown) | [`rules_markdown`](https://github.com/tomato-bazel/rules/tree/main/rules_markdown) | `rules_markdown` | 0.0.3 |
| [tomato-bazel/rules_mdbook](https://github.com/tomato-bazel/rules_mdbook) | [`rules_mdbook`](https://github.com/tomato-bazel/rules/tree/main/rules_mdbook) | `rules_mdbook` | 0.3.1 |
| [tomato-bazel/rules_meson](https://github.com/tomato-bazel/rules_meson) | [`rules_meson`](https://github.com/tomato-bazel/rules/tree/main/rules_meson) | `rules_meson` | 0.0.1 |
| [tomato-bazel/rules_nextjs](https://github.com/tomato-bazel/rules_nextjs) | [`rules_nextjs`](https://github.com/tomato-bazel/rules/tree/main/rules_nextjs) | `rules_nextjs` | 0.3.0 |
| [tomato-bazel/rules_openapi](https://github.com/tomato-bazel/rules_openapi) | [`rules_openapi`](https://github.com/tomato-bazel/rules/tree/main/rules_openapi) | `rules_openapi` | 0.4.0 |
| [tomato-bazel/rules_podman](https://github.com/tomato-bazel/rules_podman) | [`rules_podman`](https://github.com/tomato-bazel/rules/tree/main/rules_podman) | `rules_podman` | 0.0.2 |
| [tomato-bazel/rules_postgres](https://github.com/tomato-bazel/rules_postgres) | [`rules_postgres`](https://github.com/tomato-bazel/rules/tree/main/rules_postgres) | `rules_postgres` | 0.12.0 |
| [tomato-bazel/rules_puml](https://github.com/tomato-bazel/rules_puml) | [`rules_puml`](https://github.com/tomato-bazel/rules/tree/main/rules_puml) | `rules_puml` | 0.0.2 |
| [tomato-bazel/rules_rdf](https://github.com/tomato-bazel/rules_rdf) | [`rules_rdf`](https://github.com/tomato-bazel/rules/tree/main/rules_rdf) | `rules_rdf` | 0.4.0 |
| [tomato-bazel/rules_readme](https://github.com/tomato-bazel/rules_readme) | [`rules_readme`](https://github.com/tomato-bazel/rules/tree/main/rules_readme) | `rules_readme` | 0.0.3 |
| [tomato-bazel/rules_schema_org](https://github.com/tomato-bazel/rules_schema_org) | [`rules_schema_org`](https://github.com/tomato-bazel/rules/tree/main/rules_schema_org) | `rules_schema_org` | 0.0.3 |
| [tomato-bazel/rules_ssh_tui](https://github.com/tomato-bazel/rules_ssh_tui) | [`rules_ssh_tui`](https://github.com/tomato-bazel/rules/tree/main/rules_ssh_tui) | `rules_ssh_tui` | 0.0.5 |
| [tomato-bazel/rules_storybook](https://github.com/tomato-bazel/rules_storybook) | [`rules_storybook`](https://github.com/tomato-bazel/rules/tree/main/rules_storybook) | `rules_storybook` | 0.2.0 |
| [tomato-bazel/rules_systemd](https://github.com/tomato-bazel/rules_systemd) | [`rules_systemd`](https://github.com/tomato-bazel/rules/tree/main/rules_systemd) | `rules_systemd` | 0.0.1 |
| [tomato-bazel/rules_tap](https://github.com/tomato-bazel/rules_tap) | [`rules_tap`](https://github.com/tomato-bazel/rules/tree/main/rules_tap) | `rules_tap` | 0.0.3 |
| [tomato-bazel/rules_tectonic](https://github.com/tomato-bazel/rules_tectonic) | [`rules_tectonic`](https://github.com/tomato-bazel/rules/tree/main/rules_tectonic) | `rules_tectonic` | 0.2.0 |
| [tomato-bazel/rules_tla](https://github.com/tomato-bazel/rules_tla) | [`rules_tla`](https://github.com/tomato-bazel/rules/tree/main/rules_tla) | `rules_tla` | 0.2.0 |
| [tomato-bazel/rules_tomato](https://github.com/tomato-bazel/rules_tomato) | [`rules_tomato`](https://github.com/tomato-bazel/rules/tree/main/rules_tomato) | `rules_tomato` | 0.1.2 |
| [tomato-bazel/rules_uv](https://github.com/tomato-bazel/rules_uv) | [`rules_uv`](https://github.com/tomato-bazel/rules/tree/main/rules_uv) | `rules_uv` | 0.7.4 |
| [tomato-bazel/rules_vite](https://github.com/tomato-bazel/rules_vite) | [`rules_vite`](https://github.com/tomato-bazel/rules/tree/main/rules_vite) | `rules_vite` | 0.1.1 |
| [tomato-bazel/rules_vscode](https://github.com/tomato-bazel/rules_vscode) | [`rules_vscode`](https://github.com/tomato-bazel/rules/tree/main/rules_vscode) | `rules_vscode` | 0.0.2 |
| [tomato-bazel/rules_web](https://github.com/tomato-bazel/rules_web) | [`rules_web`](https://github.com/tomato-bazel/rules/tree/main/rules_web) | `rules_web` | 0.0.1 |
| [tomato-bazel/rules_xsd](https://github.com/tomato-bazel/rules_xsd) | [`rules_xsd`](https://github.com/tomato-bazel/rules/tree/main/rules_xsd) | `rules_xsd` | 0.0.1 |

Nested test-only module (not a published product):

| Path | `module(name)` | Version |
|---|---|---|
| [`rules_nextjs/examples/minimal-app`](https://github.com/tomato-bazel/rules/tree/main/rules_nextjs/examples/minimal-app) | `minimal_app` | 0.0.0 |

The registry ([tomato-bazel/bazel-registry](https://github.com/tomato-bazel/bazel-registry))
stays a separate publishing surface. `brand`, `docs`, and other
non-`rules_*` repos were not imported — see the rules
[LEDGER excludes](https://github.com/tomato-bazel/rules/blob/main/LEDGER.md#excludes).

## fastverk/plugin-shell

Private console-plugin vehicle. Sixteen imported modules; two absorbs
that must not appear as their own module directories.

| Legacy repo | Path | `module(name)` | Version |
|---|---|---|---|
| fastverk/plugin-agents | `plugin-agents` | `plugin_agents` | 0.0.1 |
| fastverk/plugin-apm | `plugin-apm` | `plugin_apm` | 0.0.1 |
| fastverk/plugin-builds | `plugin-builds` | `plugin_builds` | 0.0.1 |
| fastverk/plugin-chat | `plugin-chat` | `plugin_chat` | 0.0.1 |
| fastverk/plugin-compliance | `plugin-compliance` | `plugin-compliance` | 0.0.1 |
| fastverk/plugin-depot | `plugin-depot` | `plugin_depot` | 0.0.1 |
| fastverk/plugin-estate | `plugin-estate` | `plugin_estate` | 0.0.1 |
| fastverk/plugin-fleet | `plugin-fleet` | `plugin_fleet` | 0.0.1 |
| fastverk/plugin-forge | `plugin-forge` | `plugin_forge` | 0.0.1 |
| fastverk/plugin-integrations | `plugin-integrations` | `plugin_integrations` | 0.0.1 |
| fastverk/plugin-mycelium | `plugin-mycelium` | `plugin_mycelium` | 0.0.1 |
| fastverk/plugin-polyglot | `plugin-polyglot` | `plugin_polyglot` | 0.0.1 |
| fastverk/plugin-registry | `plugin-registry` | `plugin_registry` | 0.0.1 |
| fastverk/plugin-tbzl | `plugin-tbzl` | `plugin_tbzl` | 0.0.1 |
| fastverk/plugin-workspaces | `plugin-workspaces` | `plugin_workspaces` | 0.0.1 |
| fastverk/plugin-ws-proxy | `plugin-ws-proxy` | `plugin_ws_proxy` | 0.0.1 |

| Legacy repo | Path | Disposition |
|---|---|---|
| fastverk/plugin-org | `plugin-estate` | **pending absorb** — not an independent imported module |
| fastverk/plugin-planning | [`platform/wave`](https://github.com/fastverk/platform/tree/main/wave) | **absorb** into `wave` — not a plugin-shell module |

## fastverk/contracts

This git repo **is** one Bazel module:

| Path | `module(name)` | Version |
|---|---|---|
| [repository root](https://github.com/fastverk/contracts) | `fastverk_contracts` | 0.0.1 |

Legacy proto sources were copied into that one module. They are **not**
redeclared under their implementation names (`forge`, `tracker`,
`service_finder`, `wave`, `fastverk_agents`). Publishing proto-only
modules under those names would collide with the implementation
identities that still live in [`platform`](https://github.com/fastverk/platform)
and private `fastverk/agents`.

| Proto package | Legacy repo | Path in this vehicle |
|---|---|---|
| `forge.v1` | [fastverk/forge](https://github.com/fastverk/forge) | [`proto/forge/v1`](https://github.com/fastverk/contracts/tree/main/proto/forge/v1) |
| `tracker.v1` | [fastverk/tracker](https://github.com/fastverk/tracker) | [`proto/tracker/v1`](https://github.com/fastverk/contracts/tree/main/proto/tracker/v1) |
| `fastverk.finder.v1` | [fastverk/service-finder](https://github.com/fastverk/service-finder) | [`proto/fastverk/finder/v1`](https://github.com/fastverk/contracts/tree/main/proto/fastverk/finder/v1) |
| `wave.v1` | [fastverk/wave](https://github.com/fastverk/wave) | [`proto/wave/v1`](https://github.com/fastverk/contracts/tree/main/proto/wave/v1) |
| `agent.v1` | [fastverk/agents](https://github.com/fastverk/agents) (private) | [`proto/agent/v1`](https://github.com/fastverk/contracts/tree/main/proto/agent/v1) |

```python
bazel_dep(name = "fastverk_contracts", version = "0.0.1")
```

## fastverk/platform

Gateway / adapter implementations. Public protos are in `contracts`,
not here.

| Legacy repo | Path | `module(name)` | Version |
|---|---|---|---|
| [fastverk/forge](https://github.com/fastverk/forge) | [`forge`](https://github.com/fastverk/platform/tree/main/forge) | `forge` | 0.0.6 |
| [fastverk/tracker](https://github.com/fastverk/tracker) | [`tracker`](https://github.com/fastverk/platform/tree/main/tracker) | `tracker` | 0.0.4 |
| [fastverk/service-finder](https://github.com/fastverk/service-finder) | [`service-finder`](https://github.com/fastverk/platform/tree/main/service-finder) | `service_finder` | 0.0.1 |
| [fastverk/wave](https://github.com/fastverk/wave) | [`wave`](https://github.com/fastverk/platform/tree/main/wave) | `wave` | 0.1.0 |

All four source repos are [retired](consolidation.md): edit here, not there.

| Legacy repo | Path | Disposition |
|---|---|---|
| fastverk/plugin-planning | [`wave`](https://github.com/fastverk/platform/tree/main/wave) | **absorb** — not a module directory |
| fastverk/geetch (private) | — | **pending** — optional later; not imported |

Directory names match the GitHub repo (`service-finder`); Bazel
`module(name)` may differ (`service_finder`).

## fastverk/desktop

| Legacy repo | Path | `module(name)` | Version |
|---|---|---|---|
| [fastverk/fvkit](https://github.com/fastverk/fvkit) | [`fvkit`](https://github.com/fastverk/desktop/tree/main/fvkit) | `fvkit` | 0.0.8 |
| [fastverk/fastverk-app](https://github.com/fastverk/fastverk-app) | [`fastverk-app`](https://github.com/fastverk/desktop/tree/main/fastverk-app) | `fastverk-app` | 0.0.2 |

Both source repos are [retired](consolidation.md): edit here, not there.

No absorb rows. [`brand`](https://github.com/fastverk/brand) stays its
own repo.

## fastverk/spec

Native spine — not a subtree-import of sibling vehicles. Two Bazel
modules in this git repo; do not rename either.

| Path | `module(name)` | Version | Notes |
|---|---|---|---|
| [repository root](https://github.com/fastverk/spec) | `spec` | 0.8.3 | published framework |
| [`smoke/consumer`](https://github.com/fastverk/spec/tree/main/smoke/consumer) | `spec_smoke_consumer` | 0.0.0 | in-repo registry-consumer smoke only; not a published product |

```python
bazel_dep(name = "spec", version = "0.8.3")
```

Tags stay root `vX.Y.Z` and must match `module(version)`.

## See also

- **[Consolidation](consolidation.md)** — which source repos are
  retired, what retirement means, and the remaining sequence.
- **[The constellation](constellation.md)** — registry catalog (names
  and versions consumers pin).
- **[The platform](platform.md)** — products that sit on these modules.
- **[Quick start](quickstart.md)** — wire the registry into a Bazel
  build.
- **[Philosophy](philosophy.md)** — why modules stay independently
  versioned.
