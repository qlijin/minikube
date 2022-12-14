#!/bin/bash

# Copyright 2022 The Kubernetes Authors All rights reserved.
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

set -eux -o pipefail

if [ "$#" -ne 2 ]; then
  echo "Usage: update_cri_dockerd.sh <version> <archlist>" >&2
  exit 1
fi

readonly version=$1
archlist=$2

IFS=, read -a archarray <<< "$archlist"

tmpdir=$(mktemp -d)
pushd $tmpdir
git clone -n https://github.com/Mirantis/cri-dockerd
cd cri-dockerd
git checkout $version

for (( i=0; i < ${#archarray[*]}; i++ ))
do
	arch=${archarray[i]#"linux/"}
	# If https://github.com/Mirantis/cri-dockerd/blob/master/packaging/Makefile changes, then this will almost certainly need to change
	env GOOS=linux GOARCH=$arch CGO_ENABLED=0 go build -ldflags "-X github.com/Mirantis/cri-dockerd/cmd/version.GitCommit=${version:0:7}" -o cri-dockerd-$arch
	gsutil cp cri-dockerd-$arch gs://kicbase-artifacts/cri-dockerd/$version/$arch/cri-dockerd

done

gsutil cp ./packaging/systemd/cri-docker.service gs://kicbase-artifacts/cri-dockerd/$version/cri-docker.service
gsutil cp ./packaging/systemd/cri-docker.socket gs://kicbase-artifacts/cri-dockerd/$version/cri-docker.socket

popd
rm -rf $tmpdir
