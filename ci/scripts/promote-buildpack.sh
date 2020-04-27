#!/bin/bash

set -eu

[[ "${DEBUG,,}" == "true" ]] && set -x

# Copyright 2017-Present Pivotal Software, Inc. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

cf api $CF_API_URI --skip-ssl-validation
cf auth $CF_USERNAME $CF_PASSWORD

function promote(){
  target_buildpack_name=$1
  stack_name=$2

  echo Enabling buildpack ${target_buildpack_name} ${stack_name}...

  if [ "$stack_name" == null ] ; then
    set +e
    existing_buildpack=$(cf buildpacks | grep "${target_buildpack_name}\s")
    set -e
    cf_args=""

    buildpack_zip=$(find buildpack/*.zip | head -1)
  else
    set +e
    existing_buildpack=$(cf buildpacks | grep "${target_buildpack_name}\s" | grep "${stack_name}")
    set -e

    buildpack_zip=$(find buildpack/*-$stack_name-*.zip | head -1)
    [[ -z "$buildpack_zip" ]] && buildpack_zip=$(find buildpack/*.zip | head -1)
    cf_args="-s $stack_name"
  fi

  if [ -z "$existing_buildpack" ]; then
    count=$(cf buildpacks | grep -E ".zip" -c)
    new_position=$(expr $count + 1)
    cf create-buildpack $target_buildpack_name $buildpack_zip $new_position --enable
  else
    cf update-buildpack $target_buildpack_name -p $buildpack_zip $cf_args --enable
  fi
}

for STACK_NAME in $STACKS;
do
  promote $TARGET_BUILDPACK_NAME $STACK_NAME
done
