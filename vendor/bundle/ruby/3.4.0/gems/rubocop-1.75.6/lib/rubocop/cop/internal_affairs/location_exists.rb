# frozen_string_literal: true

module RuboCop
  module Cop
    module InternalAffairs
      # When a node location may not exist, `Node#loc?` or `Node#loc_is?`
      # can be used instead of calling `Node#respond_to?` before using
      # the value.
      #
      # @example
      #   # bad
      #   node.loc.respond_to?(:begin) && node.loc.begin
      #
      #   # good
      #   node.loc?(:begin)
      #
      #   # bad
      #   node.loc.respond_to?(:begin) && node.loc.begin.is?('(')
      #
      #   # good
      #   node.loc_is?(:begin, '(')
      #
      #   # bad
      #   node.loc.respond_to?(:begin) && node.loc.begin.source == '('
      #
      #   # good
      #   node.loc_is?(:begin, '(')
      #
      class LocationExists < Base
        extend AutoCorrector

        MSG = 'Use `%<replacement>s` instead of `%<source>s`.'

        # @!method replaceable_with_loc_is(node)
        def_node_matcher :replaceable_with_loc_is, <<~PATTERN
          (and
            (call
              (call $_receiver :loc) :respond_to?
              $(sym _location))
            {
              (call
                (call
                  (call _receiver :loc) _location) :is?
                $(str _))
              (call
                (call
                  (call
                    (call _receiver :loc) _location) :source) :==
                    $(str _))
            })
        PATTERN

        # @!method replaceable_with_loc(node)
        def_node_matcher :replaceable_with_loc, <<~PATTERN
          (and
            (call
              (call $_receiver :loc) :respond_to?
              $(sym _location))
            (call
              (call _receiver :loc) _location))
        PATTERN

        def on_and(node)
          replace_with_loc(node) || replace_with_loc_is(node)
        end

        private

        def replace_with_loc(node)
          replaceable_with_loc(node) do |receiver, location|
            if node.parent&.assignment?
              register_offense(node, replace_assignment(receiver, location))
            else
              register_offense(node, replacement(receiver, "loc?(#{location.source})"))
            end
          end
        end

        def replace_with_loc_is(node)
          replaceable_with_loc_is(node) do |receiver, location, value|
            replacement = replacement(receiver, "loc_is?(#{location.source}, #{value.source})")
            register_offense(node, replacement)
          end
        end

        def register_offense(node, replacement)
          message = format(MSG, replacement: replacement, source: node.source)

          add_offense(node, message: message) do |corrector|
            corrector.replace(node, replacement)
          end
        end

        def replacement(receiver, rest)
          "#{replace_receiver(receiver)}#{rest}"
        end

        def replace_assignment(receiver, location)
          prefix = replace_receiver(receiver)

          "#{prefix}loc#{dot(receiver)}#{location.value} if #{prefix}loc?(#{location.source})"
        end

        def replace_receiver(receiver)
          return '' unless receiver

          "#{receiver.source}#{dot(receiver)}"
        end

        def dot(node)
          node.parent.loc.dot.source
        end
      end
    end
  end
end
