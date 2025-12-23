# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for uses of literal strings converted to
      # a symbol where a literal symbol could be used instead.
      #
      # There are two possible styles for this cop.
      # `strict` (default) will register an offense for any incorrect usage.
      # `consistent` additionally requires hashes to use the same style for
      # every symbol key (ie. if any symbol key needs to be quoted it requires
      # all keys to be quoted).
      #
      # @example
      #   # bad
      #   'string'.to_sym
      #   :symbol.to_sym
      #   'underscored_string'.to_sym
      #   :'underscored_symbol'
      #   'hyphenated-string'.to_sym
      #   "string_#{interpolation}".to_sym
      #
      #   # good
      #   :string
      #   :symbol
      #   :underscored_string
      #   :underscored_symbol
      #   :'hyphenated-string'
      #   :"string_#{interpolation}"
      #
      # @example EnforcedStyle: strict (default)
      #
      #   # bad
      #   {
      #     'a': 1,
      #     "b": 2,
      #     'c-d': 3
      #   }
      #
      #   # good (don't quote keys that don't require quoting)
      #   {
      #     a: 1,
      #     b: 2,
      #     'c-d': 3
      #   }
      #
      # @example EnforcedStyle: consistent
      #
      #   # bad
      #   {
      #     a: 1,
      #     'b-c': 2
      #   }
      #
      #   # good (quote all keys if any need quoting)
      #   {
      #     'a': 1,
      #     'b-c': 2
      #   }
      #
      #   # good (no quoting required)
      #   {
      #     a: 1,
      #     b: 2
      #   }
      #
      class SymbolConversion < Base
        extend AutoCorrector
        include ConfigurableEnforcedStyle
        include SymbolHelp

        MSG = 'Unnecessary symbol conversion; use `%<correction>s` instead.'
        MSG_CONSISTENCY = 'Symbol hash key should be quoted for consistency; ' \
                          'use `%<correction>s` instead.'
        RESTRICT_ON_SEND = %i[to_sym intern].freeze

        def on_send(node)
          return unless node.receiver

          if node.receiver.type?(:str, :sym)
            register_offense(node, correction: node.receiver.value.to_sym.inspect)
          elsif node.receiver.dstr_type?
            register_offense(node, correction: ":\"#{node.receiver.value.to_sym}\"")
          end
        end

        def on_sym(node)
          return if ignored_node?(node) || properly_quoted?(node.source, node.value.inspect)

          # `alias` arguments are symbols but since a symbol that requires
          # being quoted is not a valid method identifier, it can be ignored
          return if in_alias?(node)

          # The `%I[]` and `%i[]` macros are parsed as normal arrays of symbols
          # so they need to be ignored.
          return if in_percent_literal_array?(node)

          # Symbol hash keys have a different format and need to be handled separately
          return correct_hash_key(node) if hash_key?(node)

          register_offense(node, correction: node.value.inspect)
        end

        def on_hash(node)
          # For `EnforcedStyle: strict`, hash keys are evaluated in `on_sym`
          return unless style == :consistent

          keys = node.keys.select(&:sym_type?)

          if keys.any? { |key| requires_quotes?(key) }
            correct_inconsistent_hash_keys(keys)
          else
            # If there are no symbol keys requiring quoting,
            # treat the hash like `EnforcedStyle: strict`.
            keys.each { |key| correct_hash_key(key) }
          end
        end

        private

        def register_offense(node, correction:, message: format(MSG, correction: correction))
          add_offense(node, message: message) { |corrector| corrector.replace(node, correction) }
        end

        def properly_quoted?(source, value)
          return true if style == :strict && (!source.match?(/['"]/) || value.end_with?('='))

          source == value ||
            # `Symbol#inspect` uses double quotes, but allow single-quoted
            # symbols to work as well.
            source.gsub('"', '\"').tr("'", '"') == value
        end

        def requires_quotes?(sym_node)
          sym_node.value.inspect.match?(/^:".*?"|=$/)
        end

        def in_alias?(node)
          node.parent&.alias_type?
        end

        def in_percent_literal_array?(node)
          node.parent&.array_type? && node.parent.percent_literal?
        end

        def correct_hash_key(node)
          # Although some operators can be converted to symbols normally
          # (ie. `:==`), these are not accepted as hash keys and will
          # raise a syntax error (eg. `{ ==: ... }`). Therefore, if the
          # symbol does not start with an alphanumeric or underscore, it
          # will be ignored.
          return unless node.value.to_s.match?(/\A[a-z0-9_]/i)

          correction = node.value.inspect
          correction = correction.delete_prefix(':') if node.parent.colon?
          return if properly_quoted?(node.source, correction)

          register_offense(
            node,
            correction: correction,
            message: format(MSG, correction: node.parent.colon? ? "#{correction}:" : correction)
          )
        end

        def correct_inconsistent_hash_keys(keys)
          keys.each do |key|
            ignore_node(key)

            next if requires_quotes?(key)
            next if properly_quoted?(key.source, %("#{key.value}"))

            correction = %("#{key.value}")
            register_offense(
              key,
              correction: correction,
              message: format(MSG_CONSISTENCY, correction: "#{correction}:")
            )
          end
        end
      end
    end
  end
end
