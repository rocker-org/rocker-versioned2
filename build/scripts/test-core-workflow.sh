#!/usr/bin/env bash

set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
WORKFLOW="${ROOT}/.github/workflows/core.yml"
TARGET_WORKFLOW="${ROOT}/.github/workflows/core-target.yml"
TEMPLATE="${ROOT}/build/templates/bakefiles/main.docker-bake.json"

concurrency_block=$(sed -n '/^concurrency:$/,/^[[:alnum:]_-]\+:$/p' "${WORKFLOW}" | sed '$d')
expected_concurrency_block=$'concurrency:\n  group: core-publish\n  cancel-in-progress: false'
[[ "${concurrency_block}" == "${expected_concurrency_block}" ]] || {
    echo "core workflow concurrency must serialize all publisher runs without cancellation" >&2
    exit 1
}

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
    mapfile -t actual_needs < <(awk '
        /^    needs: / { print $2; exit }
        /^    needs:$/ { in_needs=1; next }
        in_needs && /^      - / { print $2; next }
        in_needs { exit }
    ' <<<"${block}")
    expected_needs=(prepare)
    if [[ "${target}" != "r-ver" ]]; then
        expected_needs+=("${previous}")
    fi
    [[ "${actual_needs[*]}" == "${expected_needs[*]}" ]] || {
        echo "${target} is not gated by ${previous}" >&2
        exit 1
    }
    grep -Fxq "      target: ${target}" <<<"${block}" || {
        echo "${target} workflow input is missing" >&2
        exit 1
    }
    if grep -Eq '^      platforms:' <<<"${block}"; then
        echo "${target} must get its platforms from Bake, not a workflow input" >&2
        exit 1
    fi
    previous=${target}
done

if sed -n '/^    inputs:$/,/^    secrets:$/p' "${TARGET_WORKFLOW}" | grep -Eq '^      platforms:'; then
    echo "reusable core workflow must not declare a platforms input" >&2
    exit 1
fi
grep -Fq 'platform: ${{ fromJSON(needs.prepare.outputs.platforms) }}' "${TARGET_WORKFLOW}" || {
    echo "core build matrix must use platforms produced by its prepare job" >&2
    exit 1
}
grep -Fq ".target[\$target].platforms" "${TARGET_WORKFLOW}" || {
    echo "core reusable workflow must read target platforms from Bake" >&2
    exit 1
}

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
