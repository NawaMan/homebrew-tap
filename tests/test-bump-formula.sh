#!/usr/bin/env bash
# Offline test for bin/bump-formula.sh. GitHub is faked with file:// URLs
# (BUMP_API_BASE, BUMP_DOWNLOAD_BASE). Run: tests/test-bump-formula.sh
#
# Locked in here:
#   - picks the highest stable X.Y.Z / vX.Y.Z release; drafts, pre-releases,
#     --rc tags and a moving `latest` release never count
#   - one url/sha256 pair and per-platform pairs both move; livecheck's
#     `url :stable` is untouched; the formula never gets the file:// URL
#   - nothing newer (or only older) prints "unchanged" and edits nothing
#   - an explicit version is used as given, keeping the tag's `v` style
#   - a missing asset, a bad version, a url without its sha256, and urls on two
#     tags all fail without editing the formula

set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
BUMP="$HERE/../bin/bump-formula.sh"

T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
fail() { echo "❌ $*"; exit 1; }

export BUMP_API_BASE="file://$T/api"
export BUMP_DOWNLOAD_BASE="file://$T/dl"
unset GITHUB_TOKEN

release() {  # <owner/repo> <tag> <asset>...
    local repo="$1" tag="$2"; shift 2
    mkdir -p "$T/dl/$repo/releases/download/$tag"
    for a in "$@"; do echo "$repo $tag $a" > "$T/dl/$repo/releases/download/$tag/$a"; done
}
sha() { shasum -a 256 "$T/dl/$1/releases/download/$2/$3" | awk '{print $1}'; }
releases_json() {  # <owner/repo> <json>
    mkdir -p "$T/api/repos/$1"
    printf '%s\n' "$2" > "$T/api/repos/$1/releases"
}
OLD_SHA=$(printf '0%.0s' {1..64})

# ---- a single-asset formula, bare tags (like codingbooth) ----
release  o/one 1.2.0  tool
release  o/one 1.10.0 tool
release  o/one 1.11.0 tool
releases_json o/one '[
  {"tag_name":"latest",       "draft":false,"prerelease":false},
  {"tag_name":"1.11.0",       "draft":true, "prerelease":false},
  {"tag_name":"1.12.0--rc1",  "draft":false,"prerelease":false},
  {"tag_name":"2.0.0",        "draft":false,"prerelease":true},
  {"tag_name":"1.2.0",        "draft":false,"prerelease":false},
  {"tag_name":"1.10.0",       "draft":false,"prerelease":false}
]'
ONE="$T/one.rb"
write_one() {  # <tag>
    cat > "$ONE" <<RB
class One < Formula
  url "https://github.com/o/one/releases/download/$1/tool"
  sha256 "$OLD_SHA"

  livecheck do
    url :stable
  end
end
RB
}

write_one 1.2.0
out=$("$BUMP" "$ONE")
[[ "$(tail -n 1 <<<"$out")" == "changed 1.10.0" ]] || fail "one: wanted 1.10.0 (1.10 > 1.2, not draft 1.11, not latest/rc/pre): $out"
grep -qx '  url "https://github.com/o/one/releases/download/1.10.0/tool"' "$ONE" || fail "one: url: $(cat "$ONE")"
grep -qx "  sha256 \"$(sha o/one 1.10.0 tool)\"" "$ONE" || fail "one: sha256: $(cat "$ONE")"
grep -qx '    url :stable' "$ONE" || fail "one: livecheck url changed"
grep -q 'file://' "$ONE" && fail "one: download override leaked into the formula"

cp "$ONE" "$T/after.rb"
out=$("$BUMP" "$ONE")
[[ "$(tail -n 1 <<<"$out")" == "unchanged 1.10.0" ]] || fail "one: rerun: $out"
cmp -s "$ONE" "$T/after.rb" || fail "one: rerun edited the formula"

write_one 1.11.0; cp "$ONE" "$T/orig.rb"     # formula ahead of the newest release
out=$("$BUMP" "$ONE")
[[ "$(tail -n 1 <<<"$out")" == "unchanged 1.11.0" ]] || fail "one: downgraded: $out"
cmp -s "$ONE" "$T/orig.rb" || fail "one: edited when only older releases exist"

write_one 1.10.0
"$BUMP" "$ONE" 1.2.0 >/dev/null || fail "one: explicit version refused"
grep -qx '  url "https://github.com/o/one/releases/download/1.2.0/tool"' "$ONE" || fail "one: explicit version"

# ---- per-platform assets, v tags (like viewmd) ----
A=(app-darwin-arm64 app-darwin-amd64 app-linux-arm64 app-linux-amd64)
release o/multi v0.9.0 "${A[@]}"
release o/multi v0.10.0 "${A[@]}"
releases_json o/multi '[{"tag_name":"v0.9.0","draft":false,"prerelease":false},
                        {"tag_name":"v0.10.0","draft":false,"prerelease":false}]'
MULTI="$T/multi.rb"
{
    echo 'class Multi < Formula'
    for a in "${A[@]}"; do
        echo "    on_x do"
        echo "      url \"https://github.com/o/multi/releases/download/v0.9.0/$a\""
        echo "      sha256 \"$OLD_SHA\""
        echo "    end"
    done
    echo 'end'
} > "$MULTI"
out=$("$BUMP" "$MULTI")
[[ "$(tail -n 1 <<<"$out")" == "changed 0.10.0" ]] || fail "multi: $out"
for a in "${A[@]}"; do
    grep -A1 -x "      url \"https://github.com/o/multi/releases/download/v0.10.0/$a\"" "$MULTI" \
        | grep -qx "      sha256 \"$(sha o/multi v0.10.0 "$a")\"" || fail "multi: $a pair: $(cat "$MULTI")"
done
"$BUMP" "$MULTI" 0.9.0 >/dev/null || fail "multi: explicit version refused"
grep -q 'download/v0.9.0/app-linux-amd64"' "$MULTI" || fail "multi: explicit version lost the v"

# ---- refusals leave the formula alone ----
refuse() {  # <why> <formula> [<version>]
    local why="$1" f="$2"; shift 2
    cp "$f" "$T/orig.rb"
    "$BUMP" "$f" "$@" >/dev/null 2>&1 && fail "$why: accepted"
    cmp -s "$f" "$T/orig.rb" || fail "$why: formula edited"
}
rm "$T/dl/o/multi/releases/download/v0.10.0/app-linux-arm64"
refuse "one asset missing"   "$MULTI"
write_one 1.2.0
refuse "--rc version"        "$ONE" 1.12.0--rc1
refuse "release not there"   "$ONE" 3.0.0
sed -i.bak '/sha256/d' "$ONE"; rm -f "$ONE.bak"
refuse "url without sha256"  "$ONE"
write_one 1.2.0
printf '  url "https://github.com/o/one/releases/download/1.10.0/tool"\n  sha256 "%s"\n' "$OLD_SHA" >> "$ONE"
refuse "urls on two tags"    "$ONE"

echo "✅ bump-formula picks the newest stable release and rewrites every url/sha256 pair"
