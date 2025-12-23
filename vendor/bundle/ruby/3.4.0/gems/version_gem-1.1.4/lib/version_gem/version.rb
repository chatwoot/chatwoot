# frozen_string_literal: true

module VersionGem
  module Version
    VERSION = "1.1.4"
    # This would work in this gem, but not in external libraries,
    #   because version files are loaded in Gemspecs before bundler
    #   has a chance to load dependencies.
    # Instead, see lib/version_gem.rb for a solution that will work everywhere
    # extend VersionGem::Basic
  end
end
