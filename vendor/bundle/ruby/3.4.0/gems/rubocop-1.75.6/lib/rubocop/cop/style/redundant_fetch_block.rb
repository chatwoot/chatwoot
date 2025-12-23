# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Identifies places where `fetch(key) { value }` can be replaced by `fetch(key, value)`.
      #
      # In such cases `fetch(key, value)` method is faster than `fetch(key) { value }`.
      #
      # NOTE: The block string `'value'` in `hash.fetch(:key) { 'value' }` is detected
      # when frozen string literal magic comment is enabled (i.e. `# frozen_string_literal: true`),
      # but not when disabled.
      #
      # @safety
      #   This cop is unsafe because it cannot be guaranteed that the receiver
      #   does not have a different implementation of `fetch`.
      #
      # @example SafeForConstants: false (default)
      #   # bad
      #   hash.fetch(:key) { 5 }
      #   hash.fetch(:key) { true }
      #   hash.fetch(:key) { nil }
      #   array.fetch(5) { :value }
      #   ENV.fetch(:key) { 'value' }
      #
      #   # good
      #   hash.fetch(:key, 5)
      #   hash.fetch(:key, true)
      #   hash.fetch(:key, nil)
      #   array.fetch(5, :value)
      #   ENV.fetch(:key, 'value')
      #
      # @example SafeForConstants: true
      #   # bad
      #   ENV.fetch(:key) { VALUE }
      #
      #   # good
      #   ENV.fetch(:key, VALUE)
      #
      class RedundantFetchBlock < Base
        include FrozenStringLiteral
        include RangeHelp
        extend AutoCorrector

        MSG = 'Use `%<good>s` instead of `%<bad>s`.'

        # @!method redundant_fetch_block_candidate?(node)
        def_node_matcher :redundant_fetch_block_candidate?, <<~PATTERN
          (block
            $(call _ :fetch _)
            (args)
            ${nil? #basic_literal? #const_type?})
        PATTERN

        def on_block(node) # rubocop:disable InternalAffairs/NumblockHandler
          redundant_fetch_block_candidate?(node) do |send, body|
            return if should_not_check?(send, body)

            range = fetch_range(send, node)
            good = build_good_method(send, body)
            bad = build_bad_method(send, body)

            add_offense(range, message: format(MSG, good: good, bad: bad)) do |corrector|
              _, _, key = send.children
              default_value = body ? body.source : 'nil'

              corrector.replace(range, "fetch(#{key.source}, #{default_value})")
            end
          end
        end

        private

        def basic_literal?(node)
          node&.basic_literal?
        end

        def const_type?(node)
          node&.const_type?
        end

        def should_not_check?(send, body)
          (body&.const_type? && !check_for_constant?) ||
            (body&.str_type? && !check_for_string?) ||
            rails_cache?(send.receiver)
        end

        # @!method rails_cache?(node)
        def_node_matcher :rails_cache?, <<~PATTERN
          (send (const _ :Rails) :cache)
        PATTERN

        def fetch_range(send, node)
          range_between(send.loc.selector.begin_pos, node.loc.end.end_pos)
        end

        def build_good_method(send, body)
          key = send.children[2].source
          default_value = body ? body.source : 'nil'

          "fetch(#{key}, #{default_value})"
        end

        def build_bad_method(send, body)
          key = send.children[2].source
          block = body ? "{ #{body.source} }" : '{}'

          "fetch(#{key}) #{block}"
        end

        def check_for_constant?
          cop_config['SafeForConstants']
        end

        def check_for_string?
          frozen_string_literals_enabled?
        end
      end
    end
  end
end
