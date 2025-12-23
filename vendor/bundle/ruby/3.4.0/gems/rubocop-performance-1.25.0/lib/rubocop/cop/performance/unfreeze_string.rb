# frozen_string_literal: true

module RuboCop
  module Cop
    module Performance
      # In Ruby 2.3 or later, use unary plus operator to unfreeze a string
      # literal instead of `String#dup` and `String.new`.
      # Unary plus operator is faster than `String#dup`.
      #
      # @safety
      #   This cop's autocorrection is unsafe because `String.new` (without operator) is not
      #   exactly the same as `+''`. These differ in encoding. `String.new.encoding` is always
      #   `ASCII-8BIT`. However, `(+'').encoding` is the same as script encoding(e.g. `UTF-8`).
      #   if you expect `ASCII-8BIT` encoding, disable this cop.
      #
      # @example
      #   # bad
      #   ''.dup          # when Ruby 3.2 or lower
      #   "something".dup # when Ruby 3.2 or lower
      #   String.new
      #   String.new('')
      #   String.new('something')
      #
      #   # good
      #   +'something'
      #   +''
      class UnfreezeString < Base
        extend AutoCorrector
        extend TargetRubyVersion

        minimum_target_ruby_version 2.3

        MSG = 'Use unary plus to get an unfrozen string literal.'
        RESTRICT_ON_SEND = %i[dup new].freeze

        def_node_matcher :dup_string?, <<~PATTERN
          (send {str dstr} :dup)
        PATTERN

        def_node_matcher :string_new?, <<~PATTERN
          {
            (send (const nil? :String) :new {str dstr})
            (send (const nil? :String) :new)
          }
        PATTERN

        def on_send(node)
          return unless (dup_string?(node) && target_ruby_version <= 3.2) || string_new?(node)

          add_offense(node) do |corrector|
            string_value = "+#{string_value(node)}"
            string_value = "(#{string_value})" if node.parent&.send_type?

            corrector.replace(node, string_value)
          end
        end

        private

        def string_value(node)
          if node.receiver.source == 'String' && node.method?(:new)
            node.arguments.empty? ? "''" : node.first_argument.source
          else
            node.receiver.source
          end
        end
      end
    end
  end
end
