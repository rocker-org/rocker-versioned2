#!/usr/bin/env bash
# Select supported, already released versions whose RStudio targets just appeared.
set -euo pipefail

before=$1
after=$2
# A new R release already publishes the supported matrix via workflow_run.
if ! git diff --quiet "${before}" "${after}" -- build/matrix/latest.json; then
    echo '[]'
    exit 0
fi

versions=()
while IFS= read -r version; do
    file="bakefiles/${version}.docker-bake.json"
    if ! previous=$(git show "${before}:${file}" 2>/dev/null); then
        continue # A new Bake file belongs to the initial R release.
    fi
    current=$(git show "${after}:${file}")
    if jq -e '.target | has("rstudio") | not' <<<"${previous}" >/dev/null &&
        jq -e '.target | has("rstudio")' <<<"${current}" >/dev/null; then
        versions+=("${version}")
    fi
done < <(git show "${after}:build/matrix/all.json" | jq -r '.r_version[]')

# shellcheck disable=SC2016 # jq expression, not shell interpolation.
jq -cn --args '$ARGS.positional' "${versions[@]}"
