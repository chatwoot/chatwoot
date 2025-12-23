# frozen_string_literal: true

module Datadog
  module VERSION
    MAJOR = 2
    MINOR = 19
    PATCH = 0
    PRE = nil
    BUILD = nil
    # PRE and BUILD above are modified for dev gems during gem build GHA workflow

    STRING = [MAJOR, MINOR, PATCH, PRE, BUILD].compact.join('.')

    MINIMUM_RUBY_VERSION = '2.5.0'

    # Restrict the installation of this gem with untested future versions of Ruby.
    #
    # This prevents crashes in the native extension code and sends a clear signal to the
    # user that this version of the gem is untested for the host Ruby version.
    #
    # To allow testing with the next unreleased version of Ruby, the version check is performed
    # as `< #{MAXIMUM_RUBY_VERSION}`, meaning prereleases of MAXIMUM_RUBY_VERSION are allowed
    # but not stable MAXIMUM_RUBY_VERSION releases.
    MAXIMUM_RUBY_VERSION = '3.5'
  end
end
