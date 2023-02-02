#!/usr/bin/env sh

# Copyright 2018 The Kubernetes Authors. All rights reserved.
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

#set -x
set -o errexit
set -o nounset

#readonly INCUBATOR_REPO_URL=https://chartmuseum-incubator.explorer/

main() {
  setup_helm_client

  if ! sync_repo charts/stable; then
    log_error "Not all stable charts could be packaged and synced!"
    exit 1
  fi
}

setup_helm_client() {
  echo "Setting up Helm client..."

  PATH="$(pwd)/linux-amd64/:$PATH"

  helm repo add stable https://chartmuseum.renait.nl/truecharts-stable
  helm plugin install https://github.com/chartmuseum/helm-push
}

push_package() {
  chart="$1"
  if [ -d "$chart" ]; then
    chart_package="$(helm package "$chart" | cut -d":" -f2 | tr -d '[:space:]')"
  else
    chart_package="$chart"
  fi
  helm cm-push --debug -u "${HELM_REPO_USERNAME}" -p "${HELM_REPO_PASSWORD}" "${chart_package}" stable
}

sync_repo() {
  repo_dir="${1?Specify repo dir}"

  echo "Syncing repo '$repo_dir'..."

  exit_code=0

  for dir in "$repo_dir"/*; do
    if helm dependency update "$dir"; then
      if ! push_package "$dir"; then
        log_error "Problem pushing chart."
        exit_code=1
      fi
    else
      log_error "Problem building dependencies. Skipping packaging of '$dir'."
      exit_code=1
    fi
  done

  return "$exit_code"
}

log_error() {
  printf '\e[31mERROR: %s\n\e[39m' "$1" >&2
}

main
