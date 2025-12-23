#!/usr/bin/env bash

set -o pipefail

# 7-jdk is excluded by default. See https://github.com/elastic/apm-agent-ruby/pull/1367#issuecomment-1437228929
EXCLUDE=("7-jdk")

while (( "$#" )); do
  case "$1" in
    -r|--registry)
      REGISTRY=$2
      shift 2
      ;;
    -e|--exclude)
      EXCLUDE+=("$2")
      shift 2
      ;;
    -a|--action)
      ACTION=$2
      shift 2
      ;;
    --) # end argument parsing
      shift
      break
      ;;
    -*|--*=) # unsupported flags
      echo "Error: Unsupported flag $1" >&2
      exit 1
      ;;
    *) # preserve positional arguments
      shift
      ;;
  esac
done

function convert_exclude_opts() {
    for val in "${EXCLUDE[@]}"; do
      printf "! -path \"./%s/*\" " $val
    done
}

search=$(bash -c "find . -name 'Dockerfile' $(convert_exclude_opts) -print")

function report {
  if [ $1 -eq 0 ] ; then
    printf '\tImage %-60s %-10s\n' "${2}" "GENERATED"
  else
    printf '\tImage %-60s %-10s\n' "${2}" "FAILED"
  fi
}

function max {
  if [ "$1" -gt "$2" ]; then
    echo "$1"
  else
    echo "$2"
  fi
}

echo "${ACTION} docker images"

EXIT_CODE=0

for i in ${search}; do
  jdk_image=$(basename `dirname "$i"`)
  jdk_version=$(echo "$jdk_image" | cut -d'-' -f1)
  jruby=$(grep "JRUBY_VERSION" $i | cut -d" " -f 3)
  if [ "${jdk_image}" == "onbuild" ] ; then
    short=$(grep "FROM" "$i" | cut -d":" -f 2 | cut -d'-' -f1)
    jdk_version=
  else
    short=$(echo "$jruby" | cut -d'.' -f1-2)
  fi

  if [ -n "${REGISTRY}" ] ; then
    name="${REGISTRY}/jruby:${short}-${jdk_image}"
  else
    name="jruby:${short}-${jdk_image}"
  fi

  if [ "${ACTION}" == "build" ] ; then
    docker build --tag "${name}" -< $i >> output.log 2>&1
    result=$?
    report $result "${name}"
  elif [ "${ACTION}" == "push" ] ; then
    docker push "${name}" >> output.log 2>&1
    result=$?
    report $result "${name}"
  else
    ./test.sh "${name}" $jdk_version
    result=$?
  fi

  EXIT_CODE=$(max $EXIT_CODE $result)
done

exit "${EXIT_CODE}"
