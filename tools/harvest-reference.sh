#!/usr/bin/env bash
# Harvest each constellation module's committed stardoc reference (its
# `docs/*.md`, generated + diff-gated from the .bzl docstrings) into this site's
# Reference section. Modules own their API docs; we aggregate the current output
# so docs.fastverk.com tracks the world (run nightly + on repository_dispatch).
#
# Source: a local sibling checkout ($MODULES_ROOT/<name>/docs) when present
# (fast, deterministic for local builds); otherwise `gh api` (CI).
#
# Outputs: src/reference/<name>.md (gitignored — generated) + the REFERENCE
# section of src/SUMMARY.md (between its markers).
set -euo pipefail

HERE="$(cd "$(dirname "$0")/.." && pwd)"
REF="$HERE/src/reference"
SUMMARY="$HERE/src/SUMMARY.md"
MODULES_ROOT="${MODULES_ROOT:-$HERE/..}"

# Curated set (extend freely). Each is fastverk/<name> with a docs/*.md.
MODULES=(
  rules_mdbook rules_cloudformation rules_gitlab rules_jsonschema
  rules_uv rules_openapi rules_bun rules_postgres rules_rdf rules_jena
)

rm -rf "$REF"; mkdir -p "$REF"
items=""

for name in "${MODULES[@]}"; do
  out="$REF/$name.md"
  tmp="$(mktemp)"
  printf '# %s\n\n_API reference, generated from the module'\''s `.bzl` docstrings (stardoc)._\n' "$name" > "$tmp"
  found=0

  local_docs="$MODULES_ROOT/$name/docs"
  if [ -d "$local_docs" ]; then
    for md in "$local_docs"/*.md; do
      [ -e "$md" ] || continue
      case "$(basename "$md")" in README*|index*|SUMMARY*) continue;; esac
      printf '\n\n---\n\n' >> "$tmp"
      cat "$md" >> "$tmp"
      found=1
    done
  elif command -v gh >/dev/null 2>&1; then
    for path in $(gh api "repos/fastverk/$name/contents/docs" --jq '.[].path' 2>/dev/null \
                   | grep '\.md$' | grep -viE 'readme|index|summary'); do
      printf '\n\n---\n\n' >> "$tmp"
      gh api "repos/fastverk/$name/contents/$path" --jq '.content' 2>/dev/null \
        | base64 --decode >> "$tmp" && found=1
    done
  fi

  if [ "$found" = "1" ]; then
    mv "$tmp" "$out"
    items+="  - [$name](reference/$name.md)"$'\n'
    echo "harvested $name"
  else
    rm -f "$tmp"
    echo "skip $name (no docs found)"
  fi
done

# Rewrite the REFERENCE section of SUMMARY.md between its markers.
python3 - "$SUMMARY" "$items" <<'PY'
import sys
path, items = sys.argv[1], sys.argv[2]
b = "<!-- REFERENCE:BEGIN"
e = "<!-- REFERENCE:END -->"
s = open(path).read()
pre = s[: s.index(b)]
begin_line_end = s.index("\n", s.index(b)) + 1
post = s[s.index(e):]
open(path, "w").write(pre + s[s.index(b):begin_line_end] + items + post)
PY
echo "updated SUMMARY.md REFERENCE section"
