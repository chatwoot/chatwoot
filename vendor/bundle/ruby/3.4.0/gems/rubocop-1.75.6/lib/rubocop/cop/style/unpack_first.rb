# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for accessing the first element of `String#unpack`
      # which can be replaced with the shorter method `unpack1`.
      #
      # @example
      #
      #   # bad
      #   'foo'.unpack('h*').first
      #   'foo'.unpack('h*')[0]
      #   'foo'.unpack('h*').slice(0)
      #   'foo'.unpack('h*').at(0)
      #
      #   # good
      #   'foo'.unpack1('h*')
      #
      class UnpackFirst < Base
        extend AutoCorrector
        extend TargetRubyVersion

        minimum_target_ruby_version 2.4

        MSG = 'Use `unpack1(%<format>s)` instead of `%<current>s`.'
        RESTRICT_ON_SEND = %i[first [] slice at].freeze

        # @!method unpack_and_first_element?(node)
        def_node_matcher :unpack_and_first_element?, <<~PATTERN
          {
            (call $(call (...) :unpack $(...)) :first)
            (call $(call (...) :unpack $(...)) {:[] :slice :at} (int 0))
          }
        PATTERN

        def on_send(node)
          unpack_and_first_element?(node) do |unpack_call, unpack_arg|
            first_element_range = first_element_range(node, unpack_call)
            offense_range = unpack_call.loc.selector.join(node.source_range.end)
            message = format(MSG, format: unpack_arg.source, current: offense_range.source)

            add_offense(offense_range, message: message) do |corrector|
              corrector.remove(first_element_range)
              corrector.replace(unpack_call.loc.selector, 'unpack1')
            end
          end
        end
        alias on_csend on_send

        private

        def first_element_range(node, unpack_call)
          unpack_call.source_range.end.join(node.source_range.end)
        end
      end
    end
  end
end
