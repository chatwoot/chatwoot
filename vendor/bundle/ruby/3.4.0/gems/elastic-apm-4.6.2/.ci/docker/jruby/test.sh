#!/usr/bin/env bash
image=${1?image is required}
version=${2}

printf '\tTest %-30s %s\n' ${image}

if [ -n "$version" ] ; then
  test_name="Test java -version '$version'"
  docker run -t --rm $image java -version | grep -q "openjdk version \"$version\|1.$version"
  TEST_JAVA_VERSION_RESULT=$?
  if [[ $TEST_JAVA_VERSION_RESULT -eq 0 ]]; then
    printf '\t\t%-40s %s\n' "${test_name}" "PASSED"
  else
    printf '\t\t%-40s %s\n' "${test_name}" "FAILED"
  fi
fi

test_name="Test Hello World"
# random operation to verify that ruby evaluates the passed string correctly
docker run -t --rm $image jruby -e "foo = 3 * 4; puts foo" | grep -q '12'
TEST_HELLO_WORLD_RESULT=$?
if [[ $TEST_HELLO_WORLD_RESULT -eq 0 ]]; then
  printf '\t\t%-40s %s\n' "${test_name}" "PASSED"
else
  printf '\t\t%-40s %s\n' "${test_name}" "FAILED"
fi

! (( $TEST_JAVA_VERSION_RESULT || $TEST_HELLO_WORLD_RESULT ))
