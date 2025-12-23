#!/bin/bash

set -e

# Ideally, the message below is shown after everything starts up. We can't
# achieve this using healtchecks because the interval for a healtcheck is
# also an initial delay, and we don't really want to do healthchecks on 
# our DB or Redis every 2 seconds.  So, we sleep just a bit to let
# the other containers start up and vomit out their output first.
sleep 2
# Output some helpful messaging when invoking `dx/start` (which itself is
# a convenience script for `docker compose up`.
#
# Adding this to work around the mild inconvenience of the `app` container's
# entrypoint generating no output.
#
cat <<-'PROMPT'



 🎉  Dev Environment Initialized! 🎉

 ℹ️   To use this environment, open a new terminal and run

     dx/exec bash

 🕹  Use `ctrl-c` to exit.



PROMPT

# Using `sleep infinity` instead of `tail -f /dev/null`. This may be a 
# performance improvement based on the conversation on a semi-related
# StackOverflow page.
#
# @see https://stackoverflow.com/a/41655546
sleep infinity
