# fastverk/docs

The **docs.fastverk.com** site — a Bazel-native [mdBook](https://github.com/fastverk/rules_mdbook)
themed with the brand ([`@brand//mdbook:theme`](https://github.com/fastverk/brand)).

```
bazel build //:site     # -> bazel-bin/site.tar.gz (rendered HTML)
```

Until `brand >= 0.3.0` (with the mdBook theme) is published to the registry,
build with a local override:

```
bazel build //:site --override_module=brand=../brand
```

## Structure

- `src/` — handwritten guides (overview, platform, constellation, quick-start,
  philosophy), seeded from the org profile.
- `theme/` — staged from `@brand//mdbook:theme` at build time (not committed).
- `src/reference/` — **generated** (gitignored): each module's committed stardoc
  `docs/*.md`, harvested by [`tools/harvest-reference.sh`](tools/harvest-reference.sh)
  into a Reference section. Run it before building:

  ```sh
  ./tools/harvest-reference.sh        # local sibling checkouts, or `gh api` in CI
  bazel build //:site --override_module=brand=../brand
  ```

  The nightly + `repository_dispatch` rebuilds re-harvest, so API docs track the
  modules. The **module catalog** (registry-harvested) is the remaining layer.

## Publishing

`.github/workflows/docs.yml` builds the book and deploys to GitHub Pages
(custom domain `docs.fastverk.com`). It rebuilds on push, **nightly** (catalog
freshness), manual dispatch, and **`repository_dispatch: docs-rebuild`** — which
other constellation repos fire on change/release/deploy:

```sh
gh api repos/fastverk/docs/dispatches -f event_type=docs-rebuild
```

(wired centrally via `rules_ci`'s `fastverk_project` once the dep ratchet lands).
