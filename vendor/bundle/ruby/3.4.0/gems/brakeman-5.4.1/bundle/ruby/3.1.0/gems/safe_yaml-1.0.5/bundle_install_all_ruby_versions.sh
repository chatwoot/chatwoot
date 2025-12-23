#!/bin/bash

[[ -s "$HOME/.rvm/scripts/rvm" ]] && . "$HOME/.rvm/scripts/rvm"

declare -a versions=("1.8.7" "1.9.2" "1.9.3" "2.0.0" "2.1.0" "2.1.1" "2.1.2" "ruby-head" "jruby")

for i in "${versions[@]}"
do
  rvm use $i
  bundle install
done
