#!/bin/bash

set -e

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


function create_or_update(){
  local buildpack_name=$1
  local stack_name=$2
  local existing_buildpack=""
  local buildpack_zip=""

  if [ "$stack_name" == "null" ]; then
    set +e
    existing_buildpack=$(cf buildpacks | grep "${buildpack_name}\s")
    set -e

    buildpack_zip=$(find buildpack/*.zip | head -1)
  else
    set +e
    existing_buildpack=$(cf buildpacks | grep "${buildpack_name}\s" | grep "${stack_name}")
    set -e

    buildpack_zip=$(find buildpack/*-$stack_name-*.zip | head -1)
    [[ ! -z "$buildpack_zip" ]] || buildpack_zip=$(find buildpack/*.zip | head -1)
  fi

  if [ -z "$existing_buildpack" ]; then
    create $buildpack_name $buildpack_zip
  else
    update $buildpack_name $buildpack_zip $stack_name
  fi

}

function create(){
  local buildpack_name=$1
  local buildpack_zip=$2

  count=$(cf buildpacks | grep -E ".zip" -c)
  new_position=$(expr $count + 1)
  cf create-buildpack $buildpack_name $buildpack_zip $new_position --enable
}

function update(){
  local buildpack_name=$1
  local buildpack_zip=$2
  local stack_name=$3

  index=$(echo $existing_buildpack | cut -d' ' -f2 )

  if [ "$stack_name" != "null" ]; then
    cf_args="$cf_args -s $stack_name"
  fi

  cf update-buildpack $buildpack_name -p $buildpack_zip -i $index $cf_args --enable
}


for STACK_NAME in $STACKS;
do
  create_or_update $BUILDPACK_NAME $STACK_NAME
done

