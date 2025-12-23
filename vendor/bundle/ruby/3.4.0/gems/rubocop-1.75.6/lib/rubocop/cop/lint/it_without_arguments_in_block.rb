# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Emulates the following Ruby warning in Ruby 3.3.
      #
      # [source,ruby]
      # ----
      # $ ruby -e '0.times { it }'
      # -e:1: warning: `it` calls without arguments will refer to the first block param in Ruby 3.4;
      # use it() or self.it
      # ----
      #
      # `it` calls without arguments will refer to the first block param in Ruby 3.4.
      # So use `it()` or `self.it` to ensure compatibility.
      #
      # @example
      #
      #   # bad
      #   do_something { it }
      #
      #   # good
      #   do_something { it() }
      #   do_something { self.it }
      #
      class ItWithoutArgumentsInBlock < Base
        include NodePattern::Macros
        extend TargetRubyVersion

        maximum_target_ruby_version 3.3

        MSG = '`it` calls without arguments will refer to the first block param in Ruby 3.4; ' \
              'use `it()` or `self.it`.'
        RESTRICT_ON_SEND = %i[it].freeze

        def on_send(node)
          return unless (block_node = node.each_ancestor(:block).first)
          return unless block_node.arguments.empty_and_without_delimiters?

          add_offense(node) if deprecated_it_method?(node)
        end

        def deprecated_it_method?(node)
          !node.receiver && node.arguments.empty? && !node.parenthesized? && !node.block_literal?
        end
      end
    end
  end
end
