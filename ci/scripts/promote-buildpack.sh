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
  source_buildpack_name=$1
  target_buildpack_name=$2
  stack_name=$3

  echo Enabling buildpack ${source_buildpack_name} ${stack_name}...

  if [ "$stack_name" == null ] ; then
    set +e
    old_buildpack=$(cf buildpacks | grep "${target_buildpack_name}\s")
    set -e
    cf_args=""
  else
    set +e
    old_buildpack=$(cf buildpacks | grep "${target_buildpack_name}\s" | grep "${stack_name}")
    set -e
    cf_args="-s $stack_name"
  fi

  cf update-buildpack $source_buildpack_name $cf_args --enable

  if [ -n "$old_buildpack" ]; then
    index=$(echo $old_buildpack | cut -d' ' -f2)
    name=$(echo $old_buildpack | cut -d' ' -f1)

    cf delete-buildpack -f $target_buildpack_name $cf_args

    echo Updating buildpack ${source_buildpack_name} ${stack_name} index...
    cf update-buildpack $source_buildpack_name -i $index $cf_args
  fi

  cf rename-buildpack $source_buildpack_name $target_buildpack_name $cf_args
}

for STACK_NAME in $STACKS;
do
  promote $SOURCE_BUILDPACK_NAME $TARGET_BUILDPACK_NAME $STACK_NAME
done
