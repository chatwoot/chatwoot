# frozen_string_literal: true

module RuboCop
  module Cop
    module Performance
      # Checks for .times.map calls.
      # In most cases such calls can be replaced
      # with an explicit array creation.
      #
      # @safety
      #   This cop's autocorrection is unsafe because `Integer#times` does nothing if receiver is 0
      #   or less. However, `Array.new` raises an error if argument is less than 0.
      #
      #   For example:
      #
      #   [source,ruby]
      #   ----
      #   -1.times{}    # does nothing
      #   Array.new(-1) # ArgumentError: negative array size
      #   ----
      #
      # @example
      #   # bad
      #   9.times.map do |i|
      #     i.to_s
      #   end
      #
      #   # good
      #   Array.new(9) do |i|
      #     i.to_s
      #   end
      class TimesMap < Base
        extend AutoCorrector

        MESSAGE = 'Use `Array.new(%<count>s)` with a block instead of `.times.%<map_or_collect>s`'
        MESSAGE_ONLY_IF = 'only if `%<count>s` is always 0 or more'
        RESTRICT_ON_SEND = %i[map collect].freeze

        def_node_matcher :times_map_call, <<~PATTERN
          {
            (any_block $(call (call $!nil? :times) {:map :collect}) ...)
            $(call (call $!nil? :times) {:map :collect} (block_pass ...))
          }
        PATTERN

        def on_send(node)
          check(node)
        end
        alias on_csend on_send

        def on_block(node)
          check(node)
        end
        alias on_numblock on_block
        alias on_itblock on_block

        private

        def check(node)
          times_map_call(node) do |map_or_collect, count|
            next unless handleable_receiver?(node)

            add_offense(node, message: message(map_or_collect, count)) do |corrector|
              replacement = "Array.new(#{count.source}#{map_or_collect.arguments.map { |arg| ", #{arg.source}" }.join})"

              corrector.replace(map_or_collect, replacement)
            end
          end
        end

        def handleable_receiver?(node)
          receiver = node.receiver.receiver
          return true if receiver.literal? && receiver.type?(:int, :float)

          node.receiver.dot?
        end

        def message(map_or_collect, count)
          template = if count.literal?
                       "#{MESSAGE}."
                     else
                       "#{MESSAGE} #{MESSAGE_ONLY_IF}."
                     end
          format(template, count: count.source, map_or_collect: map_or_collect.method_name)
        end
      end
    end
  end
end
