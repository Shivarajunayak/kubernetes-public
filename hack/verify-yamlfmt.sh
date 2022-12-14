#!/usr/bin/env bash

# Copyright 2021 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# This script checks whether the OWNERS files need to be formatted or not by
# `yamlfmt`. Run `hack/update-yamlfmt.sh` to actually format sources.
#
# Usage: `hack/verify-yamlfmt.sh`.


set -o errexit
set -o nounset
set -o pipefail

KUBE_ROOT=$(dirname "${BASH_SOURCE[0]}")/..
export KUBE_ROOT
source "${KUBE_ROOT}/hack/lib/init.sh"

kube::util::ensure_clean_working_dir

_tmpdir="$(kube::realpath "$(mktemp -d -t verify-yamlfmt.XXXXXX)")"

_tmp_gopath="${_tmpdir}/go"
_tmp_kuberoot="${_tmp_gopath}/src/k8s.io/kubernetes"
git worktree add -f "${_tmp_kuberoot}" HEAD
kube::util::trap_add "git worktree remove -f ${_tmp_kuberoot} && rm -rf ${_tmpdir}" EXIT

find_files() {
  pushd "${_tmp_kuberoot}" >/dev/null 2>&1
  find "$(pwd)" -not \( \
      \( \
        -wholename './output' \
        -o -wholename './.git' \
        -o -wholename './_output' \
        -o -wholename './_gopath' \
        -o -wholename './release' \
        -o -wholename './target' \
        -o -wholename '*/vendor/*' \
      \) -prune \
    \) -name 'OWNERS*'
  popd >/dev/null 2>&1
}

find_files | xargs go run cmd/yamlfmt/yamlfmt.go

cd "${_tmp_kuberoot}"
changed_files=$(git status --porcelain)

if [[ -n "${changed_files}" ]]; then
  echo "!!! OWNERS files need to be updated:" >&2
  echo "${changed_files}" >&2
  echo >&2
  echo "Please run hack/update-yamlfmt.sh." >&2
  exit 1
fi
