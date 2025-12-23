# frozen_string_literal: true

module Libdatadog
  # Current libdatadog version
  LIB_VERSION = "18.1.0"

  GEM_MAJOR_VERSION = "1"
  GEM_MINOR_VERSION = "0"
  GEM_PRERELEASE_VERSION = "" # remember to include dot prefix, if needed!
  private_constant :GEM_MAJOR_VERSION, :GEM_MINOR_VERSION, :GEM_PRERELEASE_VERSION

  # The gem version scheme is lib_version.gem_major.gem_minor[.prerelease].
  # This allows a version constraint such as ~> 0.2.0.1.0 in the consumer (dd-trace-rb), in essence pinning libdatadog to
  # a specific version like = 0.2.0, but still allow a) introduction of a gem-level breaking change by bumping gem_major
  # and b) allow to push automatically picked up bugfixes by bumping gem_minor.
  VERSION = "#{LIB_VERSION}.#{GEM_MAJOR_VERSION}.#{GEM_MINOR_VERSION}#{GEM_PRERELEASE_VERSION}"
end
