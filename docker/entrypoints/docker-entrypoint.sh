#!/bin/sh

# The image's own entrypoint, so the schema gate cannot be left out of a deployment.
#
# The gate itself lives in sidekiq.sh, and until now it was wired from exactly one file:
# docker-compose.coolify.yaml. Every other compose in this repository starts the worker
# with a bare `command:`, and so does every compose an operator writes by hand or a panel
# generates, which means the protection was present precisely where somebody had
# remembered it. It went missing twice, and both times the loss was silent: ActiveRecord
# reads a model's columns once per process, a worker that boots one migration behind keeps
# that schema until it is restarted, and only the paths that CREATE a record raise.
# Containers stay healthy, queues stay empty, and messages disappear.
#
# Deciding here, by argv, instead of in a compose, is what makes the gate travel with the
# image. A compose is still free to set its own `entrypoint:` and replace this, which is
# what docker-compose.coolify.yaml does for the web container: that one has to RUN the
# migrations rather than wait for them.
#
# Everything that is not a worker execs straight through. `rails console`, `rake`, a
# shell and the web server must not wait on migrations: the web container is usually the
# one running them, and a console that blocks is a console nobody can use to fix the thing
# that is blocking it.

set -e

if [ "$#" -eq 0 ]; then
  echo "docker-entrypoint: no command given" >&2
  exit 1
fi

# Before anything can boot Rails, enterprise/ has to be in place when the edition asks for
# it: ChatwootApp.enterprise? only looks at whether the directory exists. The helper says
# nothing and does nothing unless CW_EDITION=ee, and stops the container when it cannot
# deliver the tree it was asked for.
docker/entrypoints/helpers/enterprise.sh ensure

# Two arms because the worker arrives in two shapes. `bundle exec sidekiq -C ...` carries
# `sidekiq` as its own argument, so a standalone word match finds it and a quoted
# `rails runner 'Sidekiq::Queue.new.size'` -- one argument, contents invisible to a word
# match -- correctly does not count as a worker. The substring arm covers
# `sh -c 'bundle exec sidekiq ...'`, where the whole command is a single argument.
for arg in "$@"; do
  case "$arg" in
    sidekiq | *'exec sidekiq'*)
      exec docker/entrypoints/sidekiq.sh "$@"
      ;;
  esac
done

exec "$@"
