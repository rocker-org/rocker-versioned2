#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
work=$(mktemp -d)
trap 'rm -rf "${work}"' EXIT
cd "${work}"
git init -q
git config user.name 'Recovery test'
git config user.email 'test@example.invalid'
mkdir -p bakefiles build/matrix
printf '%s\n' '{"r_version":["4.6.1","4.6.2"]}' >build/matrix/all.json
printf '%s\n' '{"r_version":["4.6.2"]}' >build/matrix/latest.json
printf '%s\n' '{"target":{"r-ver":{}}}' >bakefiles/4.6.1.docker-bake.json
cp bakefiles/4.6.1.docker-bake.json bakefiles/4.5.3.docker-bake.json
printf '%s\n' '{"target":{"r-ver":{},"rstudio":{}}}' >bakefiles/4.6.2.docker-bake.json
git add .
git commit -qm initial
before=$(git rev-parse HEAD)

# Existing target/tag edits and unsupported versions must not trigger a rebuild.
printf '%s\n' '{"target":{"r-ver":{},"rstudio":{"tags":["new-tag"]}}}' >bakefiles/4.6.2.docker-bake.json
cp bakefiles/4.6.2.docker-bake.json bakefiles/4.5.3.docker-bake.json
git add .
git commit -qm 'No availability transition'
unchanged=$(git rev-parse HEAD)
[[ $(bash "${ROOT}/build/scripts/core-rstudio-versions.sh" "${before}" "${unchanged}") == '[]' ]]

# Recover one existing version; ignore a newly created supported Bake file.
cp bakefiles/4.6.2.docker-bake.json bakefiles/4.6.1.docker-bake.json
cp bakefiles/4.6.2.docker-bake.json bakefiles/4.6.3.docker-bake.json
printf '%s\n' '{"r_version":["4.6.1","4.6.2","4.6.3"]}' >build/matrix/all.json
git add .
git commit -qm 'RStudio becomes available'
after=$(git rev-parse HEAD)
[[ $(bash "${ROOT}/build/scripts/core-rstudio-versions.sh" "${before}" "${after}") == '["4.6.1"]' ]]
# A push range with no new transition must do nothing.
[[ $(bash "${ROOT}/build/scripts/core-rstudio-versions.sh" "${after}" "${after}") == '[]' ]]

# An initial R release is already handled by the release workflow, including
# any recovery in the same multi-commit push range.
printf '%s\n' '{"r_version":["4.6.3"]}' >build/matrix/latest.json
git add .
git commit -qm 'New R release'
release=$(git rev-parse HEAD)
[[ $(bash "${ROOT}/build/scripts/core-rstudio-versions.sh" "${before}" "${release}") == '[]' ]]

echo 'RStudio recovery selection tests passed'
