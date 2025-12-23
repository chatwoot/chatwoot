#!/bin/bash -e
# Copyright 2016 Google Inc. Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

# Echoes the sass-spec Git ref that should be checked out for the current Travis
# run. If we're running specs for a pull request which refers to a sass-spec
# pull request, we'll run against the latter rather than sass-spec master.

default=master

if [ "$TRAVIS_PULL_REQUEST" == "false" ]; then
  >&2 echo "TRAVIS_PULL_REQUEST: $TRAVIS_PULL_REQUEST."
  >&2 echo "Ref: $default."
  echo "$default"
  exit 0
fi

>&2 echo "Fetching pull request $TRAVIS_PULL_REQUEST..."

url=https://api.github.com/repos/sass/ruby-sass/pulls/$TRAVIS_PULL_REQUEST
if [ -z "$GITHUB_AUTH" ]; then
    >&2 echo "Fetching pull request info without authentication"
    JSON=$(curl -L -sS $url)
else
    >&2 echo "Fetching pull request info as sassbot"
    JSON=$(curl -u "sassbot:$GITHUB_AUTH" -L -sS $url)
fi
>&2 echo "$JSON"

RE_SPEC_PR="sass\/sass-spec(#|\/pull\/)([0-9]+)"

if [[ $JSON =~ $RE_SPEC_PR ]]; then
  ref="pull/${BASH_REMATCH[2]}/head"
  >&2 echo "Ref: $ref."
  echo "$ref"
else
  >&2 echo "Ref: $default."
  echo "$default"
fi
