require 'thor'

module Bundler
  module Audit
    class CLI < ::Thor
      module Formats
        module Good
          def print_report(report,output=$stdout)
            say "I am a good format.", :green
          end
        end

        Formats.register :good, Good
      end
    end
  end
end
