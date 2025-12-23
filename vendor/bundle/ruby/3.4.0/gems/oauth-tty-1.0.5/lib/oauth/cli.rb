# frozen_string_literal: true

require "oauth/tty"

# Backwards compatibility hack.
# TODO: Remove with April 2023 release of 2.0 release of oauth gem
OAuth::CLI = OAuth::TTY::CLI
