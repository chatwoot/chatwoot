# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks for setup scattered across multiple hooks in an example group.
      #
      # Unify `before` and `after` hooks when possible.
      # However, `around` hooks are allowed to be defined multiple times,
      # as unifying them would typically make the code harder to read.
      #
      # @example
      #   # bad
      #   describe Foo do
      #     before { setup1 }
      #     before { setup2 }
      #   end
      #
      #   # good
      #   describe Foo do
      #     before do
      #       setup1
      #       setup2
      #     end
      #   end
      #
      #   # good
      #   describe Foo do
      #     around { |example| before1; example.call; after1 }
      #     around { |example| before2; example.call; after2 }
      #   end
      #
      class ScatteredSetup < Base
        include FinalEndLocation
        include RangeHelp
        extend AutoCorrector

        MSG = 'Do not define multiple `%<hook_name>s` hooks in the same ' \
              'example group (also defined on %<lines>s).'

        def on_block(node) # rubocop:disable InternalAffairs/NumblockHandler
          return unless example_group?(node)

          repeated_hooks(node).each do |occurrences|
            occurrences.each do |occurrence|
              message = message(occurrences, occurrence)
              add_offense(occurrence, message: message) do |corrector|
                autocorrect(corrector, occurrences.first, occurrence)
              end
            end
          end
        end

        private

        def repeated_hooks(node)
          hooks = RuboCop::RSpec::ExampleGroup.new(node)
            .hooks
            .select { |hook| hook.knowable_scope? && hook.name != :around }
            .group_by { |hook| [hook.name, hook.scope, hook.metadata] }
            .values
            .reject(&:one?)

          hooks.map do |hook|
            hook.map(&:to_node)
          end
        end

        def lines_msg(numbers)
          if numbers.size == 1
            "line #{numbers.first}"
          else
            "lines #{numbers.join(', ')}"
          end
        end

        def message(occurrences, occurrence)
          lines = occurrences.map(&:first_line)
          lines_except_current = lines - [occurrence.first_line]
          format(MSG, hook_name: occurrences.first.method_name,
                      lines: lines_msg(lines_except_current))
        end

        def autocorrect(corrector, first_occurrence, occurrence)
          return if first_occurrence == occurrence || !first_occurrence.body

          # Take heredocs into account
          body = occurrence.body&.source_range&.with(
            end_pos: final_end_location(occurrence).begin_pos
          )

          corrector.insert_after(first_occurrence.body,
                                 "\n#{body&.source}")
          corrector.remove(range_by_whole_lines(occurrence.source_range,
                                                include_final_newline: true))
        end
      end
    end
  end
end
