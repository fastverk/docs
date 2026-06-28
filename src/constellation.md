# The constellation

The `rules_*` registry — one module per concern, composed into hermetic builds.
Each lands in the **fastverk bazel-registry**; per-module API reference
(stardoc-generated) and this catalog are kept current by the nightly rebuild.

## Categories

- **Language toolchains** — `rules_uv`, `rules_lean`, `rules_postgres`, `rules_autoconf`
- **API + schema** — `rules_jsonschema`, `rules_openapi`, `rules_aip`
- **Web + bundlers** — `rules_bun`, `rules_chrome`, `rules_nextjs`, `rules_storybook`, `rules_vite`, `rules_docker`
- **CI + cloud** — `rules_github`, `rules_gitlab`, `rules_ci`, `rules_cloudformation`, `rules_helm`
- **Docs + publishing** — `rules_mdbook`, `rules_tectonic`, `rules_readme`, `rules_markdown`
- **Semantic web** — `rules_jena`, `rules_rdf`, `rules_schema_org`

## Modules

<!-- BOTNOC:MODULES_TABLE — generated from the bazel-registry by botnoc-readme; do not hand-edit. -->

| Module | Latest | Repo |
|---|---|---|
| [`rules_autoconf`](https://github.com/fastverk/rules_autoconf) | 0.1.0 | fastverk/rules_autoconf |
| [`rules_beam`](https://github.com/fastverk/rules_beam) | 0.0.2 | fastverk/rules_beam |
| [`rules_bun`](https://github.com/fastverk/rules_bun) | 0.2.0 | fastverk/rules_bun |
| [`rules_chrome`](https://github.com/fastverk/rules_chrome) | 0.1.0 | fastverk/rules_chrome |
| [`rules_cloudformation`](https://github.com/fastverk/rules_cloudformation) | 0.8.0 | fastverk/rules_cloudformation |
| [`rules_github`](https://github.com/fastverk/rules_github) | 0.1.2 | fastverk/rules_github |
| [`rules_gitlab`](https://github.com/fastverk/rules_gitlab) | 0.3.2 | fastverk/rules_gitlab |
| [`rules_helm`](https://github.com/fastverk/rules_helm) | 0.1.0 | fastverk/rules_helm |
| [`rules_jsonschema`](https://github.com/fastverk/rules_jsonschema) | 0.3.0 | fastverk/rules_jsonschema |
| [`rules_lean`](https://github.com/fastverk/rules_lean) | 0.5.3 | fastverk/rules_lean |
| [`rules_mdbook`](https://github.com/fastverk/rules_mdbook) | 0.3.1 | fastverk/rules_mdbook |
| [`rules_openapi`](https://github.com/fastverk/rules_openapi) | 0.2.1 | fastverk/rules_openapi |
| [`rules_postgres`](https://github.com/fastverk/rules_postgres) | 0.4.1 | fastverk/rules_postgres |
| [`rules_tectonic`](https://github.com/fastverk/rules_tectonic) | 0.2.0 | fastverk/rules_tectonic |
| [`rules_uv`](https://github.com/fastverk/rules_uv) | 0.7.4 | fastverk/rules_uv |

<!-- /BOTNOC:MODULES_TABLE -->

> The full table (~35 modules) is regenerated nightly from the registry; this is
> a representative snapshot. See each module's own API reference for setup.

## Registry split

fastverk and citizen-sh publish from separate registries:

- fastverk modules: `https://raw.githubusercontent.com/fastverk/bazel-registry/main/`
- citizen-sh modules: `https://raw.githubusercontent.com/citizen-sh/bazel-registry/main/`

Use the registry chain that matches the modules you consume.
