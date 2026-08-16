#!/usr/bin/env bash

set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
TMP_DIR=$(mktemp -d)
trap 'rm -rf "${TMP_DIR}"' EXIT

VERSION=$(jq -er '.r_version[0]' "${ROOT}/build/matrix/latest.json")
BAKE_FILE="${ROOT}/bakefiles/${VERSION}.docker-bake.json"
GITHUB_OUTPUT="${TMP_DIR}/output" "${ROOT}/build/scripts/core-publish.sh" \
    config "${BAKE_FILE}" r-ver linux/arm64
grep -Fxq 'docker_repository=docker.io/rocker/r-ver' "${TMP_DIR}/output"
grep -Fxq 'ghcr_repository=ghcr.io/rocker-org/r-ver' "${TMP_DIR}/output"
grep -Fxq 'platform_pair=linux-arm64' "${TMP_DIR}/output"

DIGEST="sha256:$(printf 'a%.0s' {1..64})"
"${ROOT}/build/scripts/core-publish.sh" write-metadata \
    "${BAKE_FILE}" "${VERSION}" r-ver linux/arm64 "${DIGEST}" "${TMP_DIR}/metadata.json"
jq -e --arg digest "${DIGEST}" --arg version "${VERSION}" '
    length == 2
    and all(.[]; .version == $version and .target == "r-ver"
        and .platform == "linux/arm64" and .digest == $digest)
    and ([.[].registry] | sort) == ["docker.io", "ghcr.io"]
    and ([.[].repository] | sort) == ["docker.io/rocker/r-ver", "ghcr.io/rocker-org/r-ver"]' \
    "${TMP_DIR}/metadata.json" >/dev/null

if GITHUB_OUTPUT="${TMP_DIR}/invalid" "${ROOT}/build/scripts/core-publish.sh" \
    config "${BAKE_FILE}" shiny linux/arm64 2>/dev/null; then
    echo "amd64-only target unexpectedly accepted linux/arm64" >&2
    exit 1
fi

for platform in linux/amd64 linux/arm64; do
    "${ROOT}/build/scripts/core-publish.sh" write-metadata \
        "${BAKE_FILE}" "${VERSION}" r-ver "${platform}" "${DIGEST}" \
        "${TMP_DIR}/finalize/${platform#linux/}.json"
done

export MOCK_DOCKER_LOG="${TMP_DIR}/docker.log"
docker() {
    if [[ "$*" == *"imagetools inspect"*"{{json .Image}}"* ]]; then
        printf '{"config":{"Labels":{"org.opencontainers.image.revision":"test-revision"}}}\n'
    elif [[ "$*" == *"imagetools inspect"*"{{json .Manifest}}"* ]]; then
        printf '{"digest":"sha256:%064d"}\n' 1
    elif [[ "$*" == *"imagetools inspect"*"--raw"* ]]; then
        printf '%s\n' '{"manifests":[{"platform":{"os":"linux","architecture":"amd64"}},{"platform":{"os":"unknown","architecture":"unknown"}},{"platform":{"os":"linux","architecture":"arm64"}}]}'
    elif [[ "$*" == *"imagetools create"* ]]; then
        printf '%s\n' "$*" >>"${MOCK_DOCKER_LOG}"
    else
        echo "unexpected mock docker call: $*" >&2
        return 1
    fi
}
export -f docker
"${ROOT}/build/scripts/core-publish.sh" finalize \
    "${BAKE_FILE}" "${VERSION}" r-ver "${TMP_DIR}/finalize" test-revision
[[ "$(wc -l <"${MOCK_DOCKER_LOG}")" -eq 2 ]]
grep -q -- "--tag docker.io/rocker/r-ver:${VERSION}" "${MOCK_DOCKER_LOG}"
grep -q -- '--tag ghcr.io/rocker-org/r-ver:latest' "${MOCK_DOCKER_LOG}"

echo "core publish metadata tests passed"
