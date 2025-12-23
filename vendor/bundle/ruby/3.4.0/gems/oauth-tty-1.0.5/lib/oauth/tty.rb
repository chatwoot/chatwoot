# frozen_string_literal: true

# stdlib
require "optparse"

# third party gems
require "version_gem"

# For initial release as a standalone gem, this gem must not declare oauth as a dependency,
#   because it *is* a dependency of oauth v1.1, and that would create a circular dependency.
# It will move to a declared dependency in a subsequent release.
require "oauth"

# this gem
require_relative "tty/version"
require_relative "tty/cli"
require_relative "tty/command"
require_relative "tty/commands/help_command"
require_relative "tty/commands/query_command"
require_relative "tty/commands/authorize_command"
require_relative "tty/commands/sign_command"
require_relative "tty/commands/version_command"

module OAuth
  # The namespace of this gem
  module TTY
  end
end

OAuth::TTY::Version.class_eval do
  extend VersionGem::Basic
end
