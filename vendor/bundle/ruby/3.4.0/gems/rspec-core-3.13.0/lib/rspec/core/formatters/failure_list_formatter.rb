RSpec::Support.require_rspec_core "formatters/base_formatter"

module RSpec
  module Core
    module Formatters
      # @private
      class FailureListFormatter < BaseFormatter
        Formatters.register self, :example_failed, :dump_profile, :message

        def example_failed(failure)
          output.puts "#{failure.example.location}:#{failure.example.description}"
        end

        # Discard profile and messages
        #
        # These outputs are not really relevant in the context of this failure
        # list formatter.
        def dump_profile(_profile); end
        def message(_message); end
      end
    end
  end
end
