#!/usr/bin/env bash
# Harvest the full module catalog from the fastverk bazel-registry into the
# constellation page (the BOTNOC:MODULES_TABLE markers in src/constellation.md).
# Each module's metadata.json gives its homepage + version list; the latest
# (semver-max) version + source repo make the row. Run nightly + on dispatch so
# the catalog tracks new modules + releases.
#
# Source: a local bazel-registry checkout ($REGISTRY) when present; otherwise
# fetch each metadata.json via `gh api` into a temp tree.
set -euo pipefail

HERE="$(cd "$(dirname "$0")/.." && pwd)"
PAGE="$HERE/src/constellation.md"
REGISTRY="${REGISTRY:-$HERE/../bazel-registry/modules}"

cleanup=""
if [ ! -d "$REGISTRY" ]; then
  command -v gh >/dev/null 2>&1 || { echo "no registry checkout + no gh" >&2; exit 1; }
  tmp="$(mktemp -d)"; cleanup="$tmp"
  for name in $(gh api repos/fastverk/bazel-registry/contents/modules --jq '.[].name' 2>/dev/null); do
    mkdir -p "$tmp/$name"
    gh api "repos/fastverk/bazel-registry/contents/modules/$name/metadata.json" --jq '.content' 2>/dev/null \
      | base64 --decode > "$tmp/$name/metadata.json" 2>/dev/null || true
  done
  REGISTRY="$tmp"
fi

REGISTRY="$REGISTRY" PAGE="$PAGE" python3 <<'PY'
import json, os
registry, page = os.environ["REGISTRY"], os.environ["PAGE"]

def semver_key(v):
    out = []
    for p in v.replace("-", ".").split("."):
        out.append((0, int(p)) if p.isdigit() else (1, p))
    return out

mods = []
for name in sorted(os.listdir(registry)):
    meta_path = os.path.join(registry, name, "metadata.json")
    if not os.path.isfile(meta_path):
        continue
    try:
        m = json.load(open(meta_path))
    except Exception:
        continue
    versions = m.get("versions") or []
    latest = max(versions, key=semver_key) if versions else "—"
    homepage = m.get("homepage") or f"https://github.com/fastverk/{name}"
    repo = next((r[len("github:"):] for r in (m.get("repository") or []) if r.startswith("github:")), "")
    mods.append((name, latest, homepage, repo))

lines = ["| Module | Latest | Source |", "|---|---|---|"]
lines += [f"| [`{n}`]({h}) | {v} | {r} |" for n, v, h, r in mods]
table = "\n".join(lines)

s = open(page).read()
b = "<!-- BOTNOC:MODULES_TABLE"
e = "<!-- /BOTNOC:MODULES_TABLE -->"
pre = s[: s.index(b)]
begin_end = s.index("\n", s.index(b)) + 1
post = s[s.index(e):]
open(page, "w").write(pre + s[s.index(b):begin_end] + table + "\n" + post)
print(f"catalog: {len(mods)} modules")
PY

[ -n "$cleanup" ] && rm -rf "$cleanup" || true
