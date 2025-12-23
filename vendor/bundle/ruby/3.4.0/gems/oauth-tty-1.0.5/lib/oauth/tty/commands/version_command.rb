# frozen_string_literal: true

module OAuth
  module TTY
    module Commands
      class VersionCommand < Command
        def run
          puts <<-VERSION
    OAuth Gem #{OAuth::Version::VERSION}
    OAuth TTY Gem #{OAuth::TTY::Version::VERSION}
          VERSION
        end
      end
    end
  end
end
