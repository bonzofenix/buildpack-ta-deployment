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


buildpack=$(find buildpack/*-$STACK_NAME-*.zip  --print | head -1)

if [[ ! -f buildpack ]]; then
  buildpack=$(find buildpack/*.zip -print | head -1)
fi

for STACK_NAME in $STACKS;
do
  set +e
  existing_buildpack=$(cf buildpacks | grep "${BUILDPACK_NAME}\s" | grep "${STACK_NAME}")
  set -e
  if [ -z "$existing_buildpack" ]; then
    COUNT=$(cf buildpacks | grep -E ".zip" -c)
    NEW_POSITION=$(expr $COUNT + 1)
    cf create-buildpack $BUILDPACK_NAME $buildpack $NEW_POSITION --enable
    cf update-buildpack $BUILDPACK_NAME -p $buildpack --assign-stack $STACK_NAME -i $NEW_POSITION --enable
  else
    index=$(echo $existing_buildpack | cut -d' ' -f2 )
    cf update-buildpack $BUILDPACK_NAME -p $buildpack -s $STACK_NAME -i $index --enable
  fi
done
