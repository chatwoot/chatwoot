# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for methods invoked via the `::` operator instead
      # of the `.` operator (like `FileUtils::rmdir` instead of `FileUtils.rmdir`).
      #
      # @example
      #   # bad
      #   Timeout::timeout(500) { do_something }
      #   FileUtils::rmdir(dir)
      #   Marshal::dump(obj)
      #
      #   # good
      #   Timeout.timeout(500) { do_something }
      #   FileUtils.rmdir(dir)
      #   Marshal.dump(obj)
      #
      class ColonMethodCall < Base
        extend AutoCorrector

        MSG = 'Do not use `::` for method calls.'

        # @!method java_type_node?(node)
        def_node_matcher :java_type_node?, <<~PATTERN
          (send
            (const nil? :Java) _)
        PATTERN

        def self.autocorrect_incompatible_with
          [RedundantSelf]
        end

        def on_send(node)
          return unless node.receiver && node.double_colon?
          return if node.camel_case_method?
          # ignore Java interop code like Java::int
          return if java_type_node?(node)

          add_offense(node.loc.dot) { |corrector| corrector.replace(node.loc.dot, '.') }
        end
      end
    end
  end
end
