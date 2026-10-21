#!/usr/bin/env bash
# Point a formula at the newest stable GitHub release of its project.
#
#   bin/bump-formula.sh <Formula/x.rb> [<version>]
#
# Works for any formula in this tap whose `url` lines are GitHub release assets
# (https://github.com/<owner>/<repo>/releases/download/<tag>/<asset>), each one
# directly followed by its `sha256` line: one pair (codingbooth, folio) or one
# per platform (viewmd). Homebrew reads the version from the tag in the URL, so
# no formula has a `version` line.
#
# With no <version>, it asks GitHub for the highest release that is not a draft
# or a pre-release and whose tag is X.Y.Z or vX.Y.Z (so CodingBooth's moving
# `latest` release and --rc tags never count), and bumps only when that is newer
# than the formula. With a <version> (X.Y.Z), it points the formula there
# whatever it is, keeping the tag's `v` style.
#
# Every asset of the new tag is downloaded and its sha256 taken from that
# download. Nothing is written unless all of them succeed.
#
# Last line of output: "changed <version>" or "unchanged <version>".
#
# BUMP_API_BASE and BUMP_DOWNLOAD_BASE override https://api.github.com and
# https://github.com (tests use file:// URLs); the formula always gets the
# github.com URL. GITHUB_TOKEN, when set, authenticates the API call.

set -euo pipefail

API_BASE="${BUMP_API_BASE:-https://api.github.com}"
DOWNLOAD_BASE="${BUMP_DOWNLOAD_BASE:-https://github.com}"

die() { echo "❌ $*" >&2; exit 1; }

if [[ $# -lt 1 || $# -gt 2 || "${1:-}" == -h || "${1:-}" == --help ]]; then
    echo "Usage: bin/bump-formula.sh <Formula/x.rb> [<version X.Y.Z>]" >&2
    exit 2
fi
FORMULA="$1"
WANT="${2:-}"
[[ -f "$FORMULA" ]] || die "No formula at $FORMULA"
if [[ -n "$WANT" && ! "$WANT" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "❌ Not a stable release version: '$WANT' (want X.Y.Z)" >&2
    exit 2
fi

URL_RE='^( *)url "https://github\.com/([^/]+)/([^/]+)/releases/download/([^/]+)/([^/"]+)"$'
SHA_RE='^( *)sha256 "[0-9a-f]{64}"$'

# ---- read the formula: one repo, one tag, every url followed by its sha256 ----
REPO="" TAG="" ASSETS=() prev_url=0 n=0
while IFS= read -r line || [[ -n "$line" ]]; do
    n=$((n + 1))
    if [[ $prev_url == 1 && ! "$line" =~ $SHA_RE ]]; then
        die "$FORMULA:$n: the line after a url is not its sha256"
    fi
    prev_url=0
    if [[ "$line" =~ ^\ *url\ \" ]]; then
        [[ "$line" =~ $URL_RE ]] || die "$FORMULA:$n: not a GitHub release asset url: $line"
        repo="${BASH_REMATCH[2]}/${BASH_REMATCH[3]}" tag="${BASH_REMATCH[4]}"
        [[ -z "$REPO" || "$REPO" == "$repo" ]] || die "$FORMULA: urls point at two repos ($REPO, $repo)"
        [[ -z "$TAG"  || "$TAG"  == "$tag"  ]] || die "$FORMULA: urls point at two tags ($TAG, $tag)"
        REPO="$repo" TAG="$tag"
        ASSETS+=("${BASH_REMATCH[5]}")
        prev_url=1
    fi
done < "$FORMULA"
[[ $prev_url == 0 ]] || die "$FORMULA: the last url has no sha256 after it"
[[ ${#ASSETS[@]} -gt 0 ]] || die "$FORMULA: no GitHub release url found"
[[ "$TAG" =~ ^(v?)([0-9]+\.[0-9]+\.[0-9]+)$ ]] || die "$FORMULA: tag '$TAG' is not X.Y.Z or vX.Y.Z"
PREFIX="${BASH_REMATCH[1]}"
CURRENT="${BASH_REMATCH[2]}"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

fetch() {  # curl arguments
    curl -fsSL --retry 5 --retry-delay 3 --retry-all-errors "$@"
}

# ---- pick the target release ----
if [[ -n "$WANT" ]]; then
    NEW="$WANT"
    NEW_TAG="${PREFIX}${WANT}"
else
    auth=()
    [[ -n "${GITHUB_TOKEN:-}" ]] && auth=(-H "Authorization: Bearer ${GITHUB_TOKEN}")
    fetch ${auth[@]+"${auth[@]}"} -H "Accept: application/vnd.github+json" \
        "${API_BASE}/repos/${REPO}/releases?per_page=100" -o "$TMP/releases.json" \
        || die "Could not list the releases of $REPO"
    # Sort on the number without the `v`, keep the tag as GitHub spells it.
    NEW_TAG=$(jq -r '.[] | select(.draft == false and .prerelease == false) | .tag_name' \
                  "$TMP/releases.json" \
              | grep -E '^v?[0-9]+\.[0-9]+\.[0-9]+$' \
              | awk '{ v = $0; sub(/^v/, "", v); print v " " $0 }' \
              | sort -V -k1,1 | tail -n 1 | cut -d' ' -f2 || true)
    [[ -n "$NEW_TAG" ]] || die "$REPO has no stable X.Y.Z release"
    NEW="${NEW_TAG#v}"
    if [[ "$NEW" == "$CURRENT" ]] \
       || [[ "$(printf '%s\n%s\n' "$CURRENT" "$NEW" | sort -V | tail -n 1)" == "$CURRENT" ]]; then
        echo "$(basename "$FORMULA" .rb): $CURRENT is the newest release of $REPO"
        echo "unchanged $CURRENT"
        exit 0
    fi
fi

# ---- download every asset of the new tag ----
# SHAS[i] belongs to the i-th url line (bash 3.2 on macOS has no assoc arrays).
SHAS=()
for asset in "${ASSETS[@]}"; do
    src="${DOWNLOAD_BASE}/${REPO}/releases/download/${NEW_TAG}/${asset}"
    fetch "$src" -o "$TMP/asset" || die "Could not download $src"
    sha=$(shasum -a 256 "$TMP/asset" | awk '{print $1}')
    SHAS+=("$sha")
    echo "${asset}  ${sha}"
done

# ---- rewrite every url/sha256 pair into a copy, then replace the formula ----
i=-1 after_url=0
while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" =~ $URL_RE ]]; then
        i=$((i + 1)) after_url=1
        printf '%surl "https://github.com/%s/releases/download/%s/%s"\n' \
            "${BASH_REMATCH[1]}" "$REPO" "$NEW_TAG" "${BASH_REMATCH[5]}"
    elif [[ $after_url == 1 && "$line" =~ $SHA_RE ]]; then
        printf '%ssha256 "%s"\n' "${BASH_REMATCH[1]}" "${SHAS[$i]}"
        after_url=0
    else
        printf '%s\n' "$line"
    fi
done < "$FORMULA" > "$TMP/new.rb"

if cmp -s "$FORMULA" "$TMP/new.rb"; then
    echo "unchanged $NEW"
else
    cat "$TMP/new.rb" > "$FORMULA"
    echo "$(basename "$FORMULA" .rb): $CURRENT → $NEW"
    echo "changed $NEW"
fi
