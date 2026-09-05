# Consolidation

[Ship vehicles](vehicles.md) describes the end state. This page is the
migration to it: which source repos are retired, which stay live, and what
"retired" means in practice.

**Git repo ≠ Bazel module** still holds. Retiring a source repo does not
rename `module(name = …)`, does not bump `module(version = …)`, and does not
break a published registry version.

## What "retired" means

A retired repo stops being an **edit surface**. It is not deleted, not
renamed, and not rewritten.

| Kept | Dropped |
|---|---|
| Git history and every tag | New commits on the default branch |
| Published registry versions, which keep resolving to the historical per-repo tags | Issues and PRs as the place work lands |
| The remote itself, so old clones and `git_override` pins keep working | Being the tree an agent or contributor edits |

Two mechanical markers make that legible:

1. A retirement banner at the top of `README.md` naming the vehicle, the
   path inside it, and the commit the repo was retired at.
2. A `retired` GitHub workflow that fails on `push` to the default branch and
   on `pull_request`, with an error naming the vehicle.

The workflow is a **signal, not a lock**. It tells a contributor (or an
agent) that they opened the wrong tree before they spend a review cycle
there. An admin can still merge over it for a genuine emergency; the correct
fix is to land the change in the vehicle instead.

### Why the repos are not archived or deleted

Archiving is a separate, manual, owner-only step, deliberately left out of
the automated pass:

- Archiving is reversible but noisy, and it hides issues.
- Deleting breaks `git_override` pins, historical registry entries, and any
  `bazel_dep` resolved from a per-repo tag.
- The vehicle's `drift.yml` audit reads each source repo's default-branch
  HEAD through the GitHub API. An archived repo still answers; a deleted one
  does not.

Archive only after the vehicle has published at least one release from its
own `<module>/vX.Y.Z` tag, so no live consumer resolves through the source
remote.

## Retired source repos

All six were subtree-imported with full history (`git subtree add`, no
`--squash`) and were **byte-identical to their vehicle copy** at retirement
— the LEDGER SHA equalled the source default-branch HEAD. Nothing was
stranded.

| Source repo | Vehicle | Path | Retired at | Module |
| --- | --- | --- | --- | --- |
| [fastverk/fvkit](https://github.com/fastverk/fvkit) | [desktop](https://github.com/fastverk/desktop) | `fvkit/` | `ca638b99` | `fvkit` 0.0.8 |
| [fastverk/fastverk-app](https://github.com/fastverk/fastverk-app) | [desktop](https://github.com/fastverk/desktop) | `fastverk-app/` | `985a7a0f` | `fastverk-app` 0.0.2 |
| [fastverk/forge](https://github.com/fastverk/forge) | [platform](https://github.com/fastverk/platform) | `forge/` | `98591f75` | `forge` 0.0.6 |
| [fastverk/tracker](https://github.com/fastverk/tracker) | [platform](https://github.com/fastverk/platform) | `tracker/` | `3927db97` | `tracker` 0.0.4 |
| [fastverk/service-finder](https://github.com/fastverk/service-finder) | [platform](https://github.com/fastverk/platform) | `service-finder/` | `abc76414` | `service_finder` 0.0.1 |
| [fastverk/wave](https://github.com/fastverk/wave) | [platform](https://github.com/fastverk/platform) | `wave/` | `c689d650` | `wave` 0.1.0 |

Consumers are unaffected. The `bazel_dep` lines do not change:

```python
bazel_dep(name = "fvkit", version = "0.0.8")
bazel_dep(name = "forge", version = "0.0.6")
```

### After retirement, `drift.yml` inverts

Each vehicle runs a daily report-only [drift audit](vehicles.md) comparing
its LEDGER SHA to the source default-branch HEAD. Before retirement, drift
meant *the vehicle is stale, pull from source*. After retirement, drift means
*someone committed to a retired repo* — the `retired` workflow was bypassed,
and the commit needs to be replayed into the vehicle and reverted at source.

The audit is unchanged; only the reading of a non-zero result changes.

## Still live, and why

Retirement applies to repos whose whole tree moved into a vehicle. These did
not move, and are not pending moves.

| Repo | Why it stays |
| --- | --- |
| `botnoc` | Console / control plane. Carved **out** of `fastverk/fastverk` deliberately; do not lift it back. |
| `agents` | K8s agent fleet operator. Only its `agent.v1` protos were consolidated into `contracts`. |
| `deploy` | Cluster GitOps: operator, BuildRun, ArgoCD app-of-apps. |
| `spec` | Native Lean/RDF spine — not a subtree of sibling repos. |
| `contracts` | Is itself a vehicle (one module, `fastverk_contracts`). |
| `catalog` | Product-as-code: tiers, features, quotas. Feeds `site`. |
| `brand`, `site`, `docs`, `pitch` | Identity, marketing, documentation. Explicitly excluded from the desktop vehicle. |
| `geetch` | Implements `forge.v1`, but is still a scaffold. **Pending** import into `platform`; see that LEDGER. |
| `fastverk` | Meta-repo. Narrowed rather than retired — see below. |
| `agent` | GitHub App identity. A stub, not a module. Distinct from `agents`. |
| Engines: `polyglot`, `agora`, `mycelium`, `pinax`, `crank`, `decomposer` | Products in their own right; consumed as modules or plugins. |
| Infra: `landing-zone`, `runners`, `images`, `badge` | AWS accounts, CI runners, build images, badge server. |
| `next.js` | External OSS fork. Not part of the constellation. |

## The `fastverk` meta-repo is narrowed, not retired

`fastverk` still owns real, unduplicated work: the `fv` product CLI,
`proto/fastverk/build/v1/graph.proto`, the devcontainer, the migration and
workspace tooling, and the org design corpus.

What it also carried were **stale forks** of trees that now live in the
desktop vehicle. Those are removed rather than retired, because they were
never the canonical copy:

| Removed from `fastverk` | Canonical home | Evidence it was stale |
| --- | --- | --- |
| `app/desktop`, `app/settings` | `desktop/fastverk-app` | The meta-repo tray had no identity RPCs and no busy-pulse; `fastverk-app` has both. |
| `tools/credhelper` | `desktop/fastverk-app` | Same crate name, older tree. |
| `tools/macos` | `desktop/fastverk-app` | `fastverk-app` also packages the Swift dashboard and `fvd-json`; the meta-repo copy packaged neither. |
| `proto/fastverk/v1/{connection,fvd,maintenance,repos}.proto` | `desktop/fvkit` | `fvkit` carries the same four plus `identity/v1` and `plugin/v1`. |

`graph.proto` stays: it is the one proto in that tree with no `fvkit`
counterpart.

## Plugin crates: one authoritative copy

`fastverk-layout`, `fastverk-mcp`, and `fastverk-plugin-server` existed twice
— in `botnoc/crates/` and in
[`fastverk-plugin-crates`](https://github.com/fastverk/fastverk-plugin-crates).
The README called botnoc authoritative. It was not:

| Crate | botnoc | fastverk-plugin-crates |
| --- | ---: | ---: |
| `fastverk-layout` | 684 lines | **1356** (adds pre-generated `proto_gen.rs`, vendored protos, tests) |
| `fastverk-mcp` | 220 lines | **304** |
| `fastverk-plugin-server` | 333 lines | **573** (adds `Caller` / `caller()` and `facade_with_mcp()`) |

Development landed in the copy labelled "mirror" and was never back-ported.
A botnoc→mirror sync would have deleted the gateway identity contract and the
MCP facade that deployed plugins depend on.

**`fastverk-plugin-crates` is authoritative.** Standalone `plugin-*` repos
already consume it by per-crate tag, and `rules_fastverk_plugin` wires it in.
The botnoc copies are the fork to converge.

Converging them means moving botnoc's six in-repo plugins from path-deps to
tagged git-deps, which changes crate resolution across an isolated
`crate_universe` boundary. That is a build-verified change, not a copy, and
is tracked separately. Until it lands, a drift guard reports when the two
diverge further, and the authority is recorded in both READMEs so nobody
"fixes" the direction by copying the wrong way.

## Sequencing

Each step is independently verifiable and none of them break a consumer.

1. **Retire the six in-sync source repos.** Banner + `retired` workflow.
   Safe now precisely *because* they are in sync — no unimported work is
   stranded. ✅
2. **Narrow the `fastverk` meta-repo.** Delete the stale forks and repoint
   the build. ✅
3. **Record authority for the plugin crates** and guard the drift. ✅
4. **Publish from vehicle tags.** Cut the next `fvkit` / `forge` release from
   `<module>/vX.Y.Z` on the vehicle via `rels`. Until this lands, no consumer
   depends on the vehicle, which is why archiving waits.
5. **Point implementations at `contracts`.** Each `platform` module
   `bazel_dep`s `fastverk_contracts` and stops exporting its own proto copy,
   with a CI ratchet so drift fails.
6. **Converge the botnoc plugin crates** onto tagged git-deps.
7. **Import `geetch`** into `platform` when it is past scaffold.
8. **Archive the retired remotes** — owner action, only after step 4.

## What consolidation must not do

- **Do not lift `botnoc` back into `fastverk`.** The 2026-06 carve-out was
  deliberate; the old `MIGRATION.md` Phase 4 that proposes it is superseded.
- **Do not collapse the vehicles into one Bazel module.** `fvkit` and
  `fastverk-app` version independently — [one thing per
  module](philosophy.md).
- **Do not merge `deploy` with `landing-zone`,** or `botnoc` with `agents`.
  Cluster GitOps, AWS account topology, console, and agent fleet are four
  planes with four failure modes.
- **Do not subtree `brand` into a vehicle.** `site` and `docs` consume it
  too; the desktop LEDGER excludes it on purpose.
- **Do not sync mirrored files by copying.** The plugin-crates inversion is
  the standing warning: the copy labelled authoritative was the stale one.
  Converge per symbol, with a diff.
