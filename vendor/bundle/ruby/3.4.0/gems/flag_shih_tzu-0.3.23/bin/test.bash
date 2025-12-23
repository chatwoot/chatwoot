#!/bin/bash --login

gem_installed() {
    num=$(gem list $1 | grep -e "^$1 " | wc -l)
    if [ $num -eq "1" ]; then
      echo "already installed $1"
    else
      echo "installing $1"
      gem install $1
    fi
    return 0
}

run_all_tests_for() {
  gemfile_location="gemfiles/Gemfile.activerecord-$2"
  rm -rf $gemfile_location.lock
  echo "rvm use $1@flag_shih_tzu-$2"
  rvm use $1@flag_shih_tzu-$2 --create
  gem_installed "bundler"
  echo "BUNDLE_GEMFILE=$gemfile_location bundle update --quiet"
  BUNDLE_GEMFILE=$gemfile_location bundle update --quiet
  echo "NOCOVER=true BUNDLE_GEMFILE=$gemfile_location bundle exec rake test"
  NOCOVER=true BUNDLE_GEMFILE=$gemfile_location bundle exec rake test
  Count=$(( $Count + 1 ))
}

# First run the tests for all versions supported on Ruby 1.9.3
COMPATIBLE_VERSIONS=(2.3.x 3.0.x 3.1.x 3.2.x)
Count=0
while [ "x${COMPATIBLE_VERSIONS[Count]}" != "x" ]
do
  rvm_ruby_version=1.9.3-p551
  rails_version=${COMPATIBLE_VERSIONS[Count]}
  run_all_tests_for $rvm_ruby_version $rails_version
done

# Then run the tests for all versions supported on Ruby 2.0.0
COMPATIBLE_VERSIONS=(3.0.x 3.1.x 3.2.x 4.0.x 4.1.x)
Count=0
while [ "x${COMPATIBLE_VERSIONS[Count]}" != "x" ]
do
  rvm_ruby_version=2.0.0-p648
  rails_version=${COMPATIBLE_VERSIONS[Count]}
  run_all_tests_for $rvm_ruby_version $rails_version
done

# Then run the tests for all versions supported on Ruby 2.1.5
COMPATIBLE_VERSIONS=(3.2.x 4.0.x 4.1.x 4.2.x)
Count=0
while [ "x${COMPATIBLE_VERSIONS[Count]}" != "x" ]
do
  rvm_ruby_version=2.1.10
  rails_version=${COMPATIBLE_VERSIONS[Count]}
  run_all_tests_for $rvm_ruby_version $rails_version
done

# Then run the tests for all versions supported on Ruby 2.2.3
COMPATIBLE_VERSIONS=(3.2.x 4.0.x 4.1.x 4.2.x)
Count=0
while [ "x${COMPATIBLE_VERSIONS[Count]}" != "x" ]
do
  rvm_ruby_version=2.2.7
  rails_version=${COMPATIBLE_VERSIONS[Count]}
  run_all_tests_for $rvm_ruby_version $rails_version
done

# Then run the tests for all versions supported on Ruby 2.5.1
COMPATIBLE_VERSIONS=(5.0.x 5.1.x 5.2.x)
Count=0
while [ "x${COMPATIBLE_VERSIONS[Count]}" != "x" ]
do
  rvm_ruby_version=2.5.1
  rails_version=${COMPATIBLE_VERSIONS[Count]}
  run_all_tests_for $rvm_ruby_version $rails_version
done

# Then run the tests for all versions supported on jruby-1.7.26
#   (which appears to pass for 3.1 - 4.2 inclusive)
# TODO: Investigate 2 failures on Rails 2.3 and 3.0
#       assert_equal true, my_spaceship.update_flag!(:jeanlucpicard, false, true)
#       assert_equal true, my_spaceship.update_flag!(:jeanlucpicard, false)
COMPATIBLE_VERSIONS=(3.1.x 3.2.x 4.0.x 4.1.x 4.2.x)
Count=0
while [ "x${COMPATIBLE_VERSIONS[Count]}" != "x" ]
do
  rvm_ruby_version=jruby-1.7.26
  rails_version=${COMPATIBLE_VERSIONS[Count]}
  run_all_tests_for $rvm_ruby_version $rails_version
done

 Then run the tests for all versions supported on jruby-9.1.8.0 (which is 9.1.5.0 in travis.yml)
   (which should be the same as the Ruby 2.2.3 compatibility set)
COMPATIBLE_VERSIONS=(3.2.x 4.0.x 4.1.x 4.2.x 5.0.x 5.1.x)
Count=0
while [ "x${COMPATIBLE_VERSIONS[Count]}" != "x" ]
do
  rvm_ruby_version=jruby-9.1.8.0
  rails_version=${COMPATIBLE_VERSIONS[Count]}
  run_all_tests_for $rvm_ruby_version $rails_version
done
