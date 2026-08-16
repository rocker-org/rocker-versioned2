#!/usr/bin/env bash

set -euo pipefail

die() {
    echo "core-publish: $*" >&2
    exit 1
}

require_file() {
    [[ -f "$1" ]] || die "file not found: $1"
}

target_json() {
    local bake_file=$1 target=$2
    jq -ce --arg target "${target}" '.target[$target] // error("unknown target: " + $target)' "${bake_file}"
}

repositories() {
    local bake_file=$1 target=$2
    target_json "${bake_file}" "${target}" |
        jq -r '.tags[] | sub(":[^/:]+$"; "")' |
        sort -u
}

platforms() {
    local bake_file=$1 target=$2
    target_json "${bake_file}" "${target}" | jq -r '.platforms[]' | sort -u
}

config() {
    local bake_file=$1 target=$2 platform=$3 output_file=${GITHUB_OUTPUT:-/dev/stdout}
    require_file "${bake_file}"
    platforms "${bake_file}" "${target}" | grep -Fxq "${platform}" ||
        die "${target} does not define platform ${platform}"

    local docker_repository ghcr_repository count
    docker_repository=$(repositories "${bake_file}" "${target}" | grep '^docker\.io/' || true)
    ghcr_repository=$(repositories "${bake_file}" "${target}" | grep '^ghcr\.io/' || true)
    count=$(repositories "${bake_file}" "${target}" | wc -l)
    [[ "${count}" -eq 2 && -n "${docker_repository}" && -n "${ghcr_repository}" ]] ||
        die "${target} must publish to exactly one docker.io and one ghcr.io repository"

    {
        echo "docker_repository=${docker_repository}"
        echo "ghcr_repository=${ghcr_repository}"
        echo "platform_pair=${platform//\//-}"
    } >>"${output_file}"
}

write_metadata() {
    local bake_file=$1 version=$2 target=$3 platform=$4 digest=$5 output_file=$6
    require_file "${bake_file}"
    [[ "${digest}" =~ ^sha256:[0-9a-f]{64}$ ]] || die "invalid digest: ${digest}"
    platforms "${bake_file}" "${target}" | grep -Fxq "${platform}" ||
        die "${target} does not define platform ${platform}"

    mkdir -p "$(dirname "${output_file}")"
    repositories "${bake_file}" "${target}" |
        jq -Rn \
            --arg version "${version}" \
            --arg target "${target}" \
            --arg platform "${platform}" \
            --arg digest "${digest}" \
            '[inputs | {
                version: $version,
                target: $target,
                platform: $platform,
                registry: split("/")[0],
                repository: .,
                digest: $digest
            }]' >"${output_file}"
}

assert_revision() {
    local reference=$1 revision=$2 image
    image=$(docker buildx imagetools inspect "${reference}" --format '{{json .Image}}')
    jq -e --arg revision "${revision}" \
        '.config.Labels["org.opencontainers.image.revision"] == $revision' \
        <<<"${image}" >/dev/null || die "revision label mismatch for ${reference}"
}

manifest_descriptor() {
    docker buildx imagetools inspect "$1" --format '{{json .Manifest}}'
}

verify_tag() {
    local tag=$1 expected_platforms_json=$2 expected_digest=$3 descriptor raw_manifest actual_platforms actual_digest
    descriptor=$(manifest_descriptor "${tag}")
    actual_digest=$(jq -er '.digest' <<<"${descriptor}")
    [[ "${actual_digest}" == "${expected_digest}" ]] ||
        die "manifest digest mismatch for ${tag}: ${actual_digest}, expected ${expected_digest}"

    raw_manifest=$(docker buildx imagetools inspect "${tag}" --raw)
    actual_platforms=$(jq -c '[.manifests[]?.platform
        | select(.os != "unknown" and .architecture != "unknown")
        | .os + "/" + .architecture] | unique | sort' <<<"${raw_manifest}")
    [[ "${actual_platforms}" == "${expected_platforms_json}" ]] ||
        die "platform mismatch for ${tag}: ${actual_platforms}, expected ${expected_platforms_json}"
}

finalize() {
    local bake_file=$1 version=$2 target=$3 metadata_dir=$4 revision=$5
    require_file "${bake_file}"
    [[ -d "${metadata_dir}" ]] || die "metadata directory not found: ${metadata_dir}"

    local combined expected_platforms_json expected_repositories_json
    combined=$(mktemp)
    find "${metadata_dir}" -type f -name '*.json' -print0 |
        sort -z |
        xargs -0 -r jq -s 'add' >"${combined}"
    jq -e 'type == "array" and length > 0' "${combined}" >/dev/null || die "no digest metadata found"

    expected_platforms_json=$(platforms "${bake_file}" "${target}" | jq -Rsc 'split("\n")[:-1] | unique | sort')
    expected_repositories_json=$(repositories "${bake_file}" "${target}" | jq -Rsc 'split("\n")[:-1] | unique | sort')
    jq -e \
        --arg version "${version}" \
        --arg target "${target}" \
        --argjson platforms "${expected_platforms_json}" \
        --argjson repositories "${expected_repositories_json}" '
        all(.[]; .version == $version and .target == $target
            and (.registry == (.repository | split("/")[0]))
            and (.digest | test("^sha256:[0-9a-f]{64}$")))
        and ([.[].platform] | unique | sort) == $platforms
        and ([.[].repository] | unique | sort) == $repositories
        and (all(group_by(.repository)[]; ([.[].platform] | unique | sort) == $platforms))
        and (length == (($platforms | length) * ($repositories | length)))' \
        "${combined}" >/dev/null || die "digest metadata does not match Bake definition"

    local repository manifest_digest published_manifest_digest= tag
    while IFS= read -r repository; do
        mapfile -t sources < <(jq -r --arg repository "${repository}" \
            '.[] | select(.repository == $repository) | .repository + "@" + .digest' "${combined}")
        mapfile -t tags < <(target_json "${bake_file}" "${target}" | jq -r --arg repository "${repository}" \
            '.tags[] | select(startswith($repository + ":"))')
        [[ "${#sources[@]}" -gt 0 && "${#tags[@]}" -gt 0 ]] || die "missing sources or tags for ${repository}"

        for source in "${sources[@]}"; do
            assert_revision "${source}" "${revision}"
        done

        create_args=()
        for tag in "${tags[@]}"; do
            create_args+=(--tag "${tag}")
        done
        docker buildx imagetools create "${create_args[@]}" "${sources[@]}"

        manifest_digest=$(manifest_descriptor "${tags[0]}" | jq -er '.digest')
        if [[ -n "${published_manifest_digest}" && "${manifest_digest}" != "${published_manifest_digest}" ]]; then
            die "registry manifest mismatch for ${target}: ${manifest_digest}, expected ${published_manifest_digest}"
        fi
        published_manifest_digest=${manifest_digest}
        for tag in "${tags[@]}"; do
            verify_tag "${tag}" "${expected_platforms_json}" "${manifest_digest}"
        done
    done < <(repositories "${bake_file}" "${target}")
    rm -f "${combined}"
}

smoke() {
    local bake_file=$1 target=$2 platform=$3 revision=$4 tag label
    require_file "${bake_file}"
    platforms "${bake_file}" "${target}" | grep -Fxq "${platform}" ||
        die "${target} does not define platform ${platform}"
    tag=$(target_json "${bake_file}" "${target}" | jq -er '.tags[] | select(startswith("docker.io/"))' | head -n1)
    docker pull --platform "${platform}" "${tag}"
    docker run --rm --platform "${platform}" "${tag}" R --version
    label=$(docker image inspect "${tag}" --format '{{index .Config.Labels "org.opencontainers.image.revision"}}')
    [[ "${label}" == "${revision}" ]] || die "revision label mismatch for ${tag}: ${label}"
}

usage() {
    cat >&2 <<'EOF'
Usage:
  core-publish.sh config BAKE_FILE TARGET PLATFORM
  core-publish.sh write-metadata BAKE_FILE VERSION TARGET PLATFORM DIGEST OUTPUT_FILE
  core-publish.sh finalize BAKE_FILE VERSION TARGET METADATA_DIR REVISION
  core-publish.sh smoke BAKE_FILE TARGET PLATFORM REVISION
EOF
    exit 2
}

command=${1:-}
[[ -n "${command}" ]] || usage
shift
case "${command}" in
    config) [[ $# -eq 3 ]] || usage; config "$@" ;;
    write-metadata) [[ $# -eq 6 ]] || usage; write_metadata "$@" ;;
    finalize) [[ $# -eq 5 ]] || usage; finalize "$@" ;;
    smoke) [[ $# -eq 4 ]] || usage; smoke "$@" ;;
    *) usage ;;
esac
