#!/usr/bin/env bash

set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
WORKFLOW="${ROOT}/.github/workflows/core.yml"
TEMPLATE="${ROOT}/build/templates/bakefiles/main.docker-bake.json"
mapfile -t EXPECTED_TARGETS < <(jq -r '.group[0].default[0].targets[]' "${TEMPLATE}")
mapfile -t ACTUAL_TARGETS < <(
    sed -n '/^jobs:/,/^  smoke-test:/p' "${WORKFLOW}" |
        sed -nE 's/^  (r-ver|rstudio|tidyverse|shiny|shiny-verse|verse|geospatial):$/\1/p'
)
[[ "${ACTUAL_TARGETS[*]}" == "${EXPECTED_TARGETS[*]}" ]] || {
    echo "core target order '${ACTUAL_TARGETS[*]}' != Bake default order '${EXPECTED_TARGETS[*]}'" >&2
    exit 1
}

previous=prepare
for target in "${EXPECTED_TARGETS[@]}"; do
    block=$(sed -n "/^  ${target}:$/,/^  [a-z][a-z-]*:$/p" "${WORKFLOW}" | sed '$d')
    grep -Eq "needs: (prepare|\[prepare, ${previous}\])$" <<<"${block}" || {
        echo "${target} is not gated by ${previous}" >&2
        exit 1
    }
    grep -Fxq "      target: ${target}" <<<"${block}" || {
        echo "${target} workflow input is missing" >&2
        exit 1
    }
    actual_platforms=$(sed -nE "s/^      platforms: '(.*)'$/\1/p" <<<"${block}")
    expected_platforms=$(jq -c --arg target "${target}" '.target[$target].platforms' "${TEMPLATE}")
    [[ "$(jq -c . <<<"${actual_platforms}")" == "${expected_platforms}" ]] || {
        echo "${target} workflow platforms do not match Bake" >&2
        exit 1
    }
    previous=${target}
done

expected_pairs=$(jq -r '.group[0].default[0].targets[] as $target
    | .target[$target].platforms[] | $target + " " + .' "${TEMPLATE}")
actual_pairs=$(awk '
    /^          - target:/ { target=$3 }
    /^            platform:/ { print target, $2 }
' "${WORKFLOW}")
[[ "${actual_pairs}" == "${expected_pairs}" ]] || {
    echo "smoke-test matrix does not cover every Bake target/platform in order" >&2
    exit 1
}

while IFS= read -r bake_file; do
    actual=$(jq -c '.group[0].default[0].targets' "${bake_file}")
    expected=$(jq -c '.group[0].default[0].targets' "${TEMPLATE}")
    [[ "${actual}" == "${expected}" ]] || {
        echo "${bake_file}: default target order differs from template" >&2
        exit 1
    }
    for target in "${EXPECTED_TARGETS[@]}"; do
        actual=$(jq -c --arg target "${target}" '.target[$target].platforms' "${bake_file}")
        expected=$(jq -c --arg target "${target}" '.target[$target].platforms' "${TEMPLATE}")
        [[ "${actual}" == "${expected}" ]] || {
            echo "${bake_file}: ${target} platforms differ from template" >&2
            exit 1
        }
    done
done < <(find "${ROOT}/bakefiles" -maxdepth 1 -name '[0-9]*.docker-bake.json' -print | sort)

echo "core workflow target order and platform matrices match the Bake definitions"
