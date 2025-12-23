# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for useless `else` in `begin..end` without `rescue`.
      #
      # NOTE: This syntax is no longer valid on Ruby 2.6 or higher.
      #
      # @example
      #
      #   # bad
      #   begin
      #     do_something
      #   else
      #     do_something_else # This will never be run.
      #   end
      #
      #   # good
      #   begin
      #     do_something
      #   rescue
      #     handle_errors
      #   else
      #     do_something_else
      #   end
      class UselessElseWithoutRescue < Base
        extend TargetRubyVersion

        MSG = '`else` without `rescue` is useless.'

        maximum_target_ruby_version 2.5

        def on_new_investigation
          processed_source.diagnostics.each do |diagnostic|
            next unless diagnostic.reason == :useless_else

            add_offense(diagnostic.location, severity: diagnostic.level)
          end
        end
      end
    end
  end
end
