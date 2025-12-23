require 'thor'

module Bundler
  module Audit
    class CLI < ::Thor
      module Formats
        module Bad
          def print_report(report,output=$stdout)
            say "I am a bad format!", :red
          end
        end

        Formats.register :incorrect, Bad
      end
    end
  end
end
