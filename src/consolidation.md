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

## The `fastverk` meta-repo: reconcile before deleting

`fastverk` owns real, unduplicated work — the `fv` product CLI,
`proto/fastverk/build/v1/graph.proto`, the devcontainer, the migration and
workspace tooling, and the org design corpus. It **also** carries trees that
duplicate the desktop vehicle: `app/desktop`, `app/settings`,
`tools/credhelper`, `tools/macos`, and four of the five protos under
`proto/fastverk/v1/`.

Those look like stale forks. **Three of them are not**, and deleting the set
on that assumption would lose shipped work.

| Duplicated tree | Ahead | Evidence |
| --- | --- | --- |
| `app/desktop` | `fastverk-app` | 426 lines vs 230; the vehicle copy has the identity RPCs and the busy-pulse tray, the meta-repo copy has neither. |
| `app/settings` | **`fastverk`** | Meta-repo last touched 2026-08-13 (*Remove BuildBuddy from the settings connect UI*, #38); the vehicle copy last touched 2026-06-28 and still offers a `buildbuddy` provider the credential helper now refuses. |
| `tools/credhelper` | **`fastverk`** | Meta-repo 2026-07-08 vs vehicle 2026-06-25 — a build fix (fetch the `fvkit` git-dep over https, not ssh). |
| `tools/macos` | `fastverk-app` | The vehicle also packages the Swift dashboard and `fvd-json`, and its `release.yml` does Developer-ID notarization plus the CDN push. The meta-repo's is the older, ad-hoc-signed path. |
| `proto/.../connection.proto` | tie | Byte-identical. Meta-repo's commit is newer but its content already matches. |
| `proto/.../repos.proto` | tie | Byte-identical. |
| `proto/.../fvd.proto` | `fvkit` | 338 lines vs 324; `fvkit` **reserved** tag 9 (`api_key`) on 2026-08-14, the meta-repo copy still declares `string api_key = 9`. |
| `proto/.../maintenance.proto` | `fvkit` | 160 lines vs 104. |

`graph.proto` is unduplicated and stays regardless.

### One logical change, landed in two repos

The `app/settings` and `fvd.proto` rows are two halves of the **same** piece
of work, and neither repo has both:

- 2026-08-13, in `fastverk`: the settings Connect panel drops the BuildBuddy
  provider and the API-key field.
- 2026-08-14, in `fvkit`: `ConnectProviderRequest.api_key` is reserved on the
  fvd IPC contract. That commit message reads *"Tracing every caller, in this
  repo and in fastverk-app, the field has no sender"* — the author had to
  trace three repos to make one change.

So `fastverk-app` still renders a provider that no longer resolves, and
`fastverk`'s copy of the contract still carries a plaintext secret field that
`fvkit` retired. This is the clearest single argument for the consolidation,
and simultaneously the reason the delete cannot be done blind.

### What that implies for sequencing

Removing these trees is a **reconciliation**, not a deletion:

1. Port the BuildBuddy removal and the credential-helper https fix from
   `fastverk` into `desktop/fastverk-app`.
2. Confirm the vehicle's `app/settings` builds — it and `app/desktop` link
   `tao` / `tray-icon` / `eframe` and are macOS-only, so this needs a macOS
   runner, not a Linux CI leg.
3. Delete the meta-repo copies, and with them `tools/macos` and the competing
   `release.yml`. The in-app self-updater watches `fastverk-app` releases, so
   the meta-repo currently publishes a `.dmg` nothing consumes.
4. Delete the four duplicated protos. They are lint-only there: `cli/fv`
   compiles `fvkit`'s protos through `@fvkit//crates/fvkit-core`, and the
   `connection.proto` parity check against the canonical cred-helper already
   runs in `fvkit` too. Keep `graph.proto`.
5. Repoint `tools/ci/bootstrap-cred-helper.sh`. It writes a `$GITHUB_TOKEN`
   shim, then rebuilds the real helper from `//tools/credhelper` and swaps it
   in. Its own comment notes the two are functionally identical on CI, so the
   shim alone suffices once the crate is gone.

Until step 2 has a green macOS build, the duplicated trees stay. A blind
delete here would ship exactly the regression this page exists to prevent.

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
2. **Record authority for the plugin crates** and make the divergence
   visible. ✅
3. **Reconcile the `fastverk` meta-repo duplicates** — port the two
   meta-repo-ahead trees into the vehicle, verify on macOS, then delete.
   Needs a macOS build; see above.
4. **Publish from vehicle tags.** Cut the next `fvkit` / `forge` release from
   `<module>/vX.Y.Z` on the vehicle via `rels`. Until this lands, no consumer
   depends on the vehicle, which is why archiving waits.
5. **Point implementations at `contracts`.** Each `platform` module
   `bazel_dep`s `fastverk_contracts` and stops exporting its own proto copy,
   with a CI ratchet so drift fails.
6. **Converge the botnoc plugin crates** onto tagged git-deps.
7. **Import `geetch`** into `platform` when it is past scaffold.
8. **Archive the retired remotes** — owner action, only after step 4.

Steps 1 and 2 are done. Step 3 is the next one with real code motion, and it
is deliberately *not* batched with step 1: retiring a repo whose tree is
identical to the vehicle's is a bookkeeping change, while reconciling one
whose tree has diverged is a build-verified merge.

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
- **Do not sync duplicated trees by copying, in either direction.** Two
  independent findings on this page say the same thing: the plugin-crate copy
  labelled authoritative was the stale one, and the meta-repo trees that look
  like abandoned forks include the *newest* copy of `app/settings`. Which
  side is ahead is a per-tree question — sometimes a per-file one — so
  converge with a diff and a date, never with a `cp -r`.
