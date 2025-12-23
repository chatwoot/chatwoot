# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks hash literal syntax.
      #
      # It can enforce either the use of the class hash rocket syntax or
      # the use of the newer Ruby 1.9 syntax (when applicable).
      #
      # A separate offense is registered for each problematic pair.
      #
      # The supported styles are:
      #
      # * ruby19 - forces use of the 1.9 syntax (e.g. `{a: 1}`) when hashes have
      # all symbols for keys
      # * hash_rockets - forces use of hash rockets for all hashes
      # * no_mixed_keys - simply checks for hashes with mixed syntaxes
      # * ruby19_no_mixed_keys - forces use of ruby 1.9 syntax and forbids mixed
      # syntax hashes
      #
      # This cop has `EnforcedShorthandSyntax` option.
      # It can enforce either the use of the explicit hash value syntax or
      # the use of Ruby 3.1's hash value shorthand syntax.
      #
      # The supported styles are:
      #
      # * always - forces use of the 3.1 syntax (e.g. {foo:})
      # * never - forces use of explicit hash literal value
      # * either - accepts both shorthand and explicit use of hash literal value
      # * consistent - forces use of the 3.1 syntax only if all values can be omitted in the hash
      # * either_consistent - accepts both shorthand and explicit use of hash literal value,
      #                       but they must be consistent
      #
      # @example EnforcedStyle: ruby19 (default)
      #   # bad
      #   {:a => 2}
      #   {b: 1, :c => 2}
      #
      #   # good
      #   {a: 2, b: 1}
      #   {:c => 2, 'd' => 2} # acceptable since 'd' isn't a symbol
      #   {d: 1, 'e' => 2} # technically not forbidden
      #
      # @example EnforcedStyle: hash_rockets
      #   # bad
      #   {a: 1, b: 2}
      #   {c: 1, 'd' => 5}
      #
      #   # good
      #   {:a => 1, :b => 2}
      #
      # @example EnforcedStyle: no_mixed_keys
      #   # bad
      #   {:a => 1, b: 2}
      #   {c: 1, 'd' => 2}
      #
      #   # good
      #   {:a => 1, :b => 2}
      #   {c: 1, d: 2}
      #
      # @example EnforcedStyle: ruby19_no_mixed_keys
      #   # bad
      #   {:a => 1, :b => 2}
      #   {c: 2, 'd' => 3} # should just use hash rockets
      #
      #   # good
      #   {a: 1, b: 2}
      #   {:c => 3, 'd' => 4}
      #
      # @example EnforcedShorthandSyntax: always
      #
      #   # bad
      #   {foo: foo, bar: bar}
      #
      #   # good
      #   {foo:, bar:}
      #
      #   # good - allowed to mix syntaxes
      #   {foo:, bar: baz}
      #
      # @example EnforcedShorthandSyntax: never
      #
      #   # bad
      #   {foo:, bar:}
      #
      #   # good
      #   {foo: foo, bar: bar}
      #
      # @example EnforcedShorthandSyntax: either (default)
      #
      #   # good
      #   {foo: foo, bar: bar}
      #
      #   # good
      #   {foo: foo, bar:}
      #
      #   # good
      #   {foo:, bar:}
      #
      # @example EnforcedShorthandSyntax: consistent
      #
      #   # bad - `foo` and `bar` values can be omitted
      #   {foo: foo, bar: bar}
      #
      #   # bad - `bar` value can be omitted
      #   {foo:, bar: bar}
      #
      #   # bad - mixed syntaxes
      #   {foo:, bar: baz}
      #
      #   # good
      #   {foo:, bar:}
      #
      #   # good - can't omit `baz`
      #   {foo: foo, bar: baz}
      #
      # @example EnforcedShorthandSyntax: either_consistent
      #
      #   # good - `foo` and `bar` values can be omitted, but they are consistent, so it's accepted
      #   {foo: foo, bar: bar}
      #
      #   # bad - `bar` value can be omitted
      #   {foo:, bar: bar}
      #
      #   # bad - mixed syntaxes
      #   {foo:, bar: baz}
      #
      #   # good
      #   {foo:, bar:}
      #
      #   # good - can't omit `baz`
      #   {foo: foo, bar: baz}
      class HashSyntax < Base
        include ConfigurableEnforcedStyle
        include HashShorthandSyntax
        include RangeHelp
        extend AutoCorrector

        MSG_19 = 'Use the new Ruby 1.9 hash syntax.'
        MSG_NO_MIXED_KEYS = "Don't mix styles in the same hash."
        MSG_HASH_ROCKETS = 'Use hash rockets syntax.'
        NO_MIXED_KEYS_STYLES = %i[ruby19_no_mixed_keys no_mixed_keys].freeze

        def on_hash(node)
          pairs = node.pairs

          return if pairs.empty?

          on_hash_for_mixed_shorthand(node)

          if style == :hash_rockets || force_hash_rockets?(pairs)
            hash_rockets_check(pairs)
          elsif style == :ruby19_no_mixed_keys
            ruby19_no_mixed_keys_check(pairs)
          elsif style == :no_mixed_keys
            no_mixed_keys_check(pairs)
          else
            ruby19_check(pairs)
          end
        end

        def ruby19_check(pairs)
          check(pairs, '=>', MSG_19) if sym_indices?(pairs)
        end

        def hash_rockets_check(pairs)
          check(pairs, ':', MSG_HASH_ROCKETS)
        end

        def ruby19_no_mixed_keys_check(pairs)
          if force_hash_rockets?(pairs)
            check(pairs, ':', MSG_HASH_ROCKETS)
          elsif sym_indices?(pairs)
            check(pairs, '=>', MSG_19)
          else
            check(pairs, ':', MSG_NO_MIXED_KEYS)
          end
        end

        def no_mixed_keys_check(pairs)
          if sym_indices?(pairs)
            check(pairs, pairs.first.inverse_delimiter, MSG_NO_MIXED_KEYS)
          else
            check(pairs, ':', MSG_NO_MIXED_KEYS)
          end
        end

        def alternative_style
          case style
          when :hash_rockets
            :ruby19
          when :ruby19, :ruby19_no_mixed_keys
            :hash_rockets
          end
        end

        private

        def autocorrect(corrector, node)
          if style == :hash_rockets || force_hash_rockets?(node.parent.pairs)
            autocorrect_hash_rockets(corrector, node)
          elsif NO_MIXED_KEYS_STYLES.include?(style)
            autocorrect_no_mixed_keys(corrector, node)
          else
            autocorrect_ruby19(corrector, node)
          end
        end

        def sym_indices?(pairs)
          pairs.all? { |p| word_symbol_pair?(p) }
        end

        def word_symbol_pair?(pair)
          return false unless pair.key.type?(:sym, :dsym)

          acceptable_19_syntax_symbol?(pair.key.source)
        end

        # rubocop:disable Metrics/CyclomaticComplexity
        def acceptable_19_syntax_symbol?(sym_name)
          sym_name.delete_prefix!(':')

          if cop_config['PreferHashRocketsForNonAlnumEndingSymbols'] &&
             # Prefer { :production? => false } over { production?: false } and
             # similarly for other non-alnum final characters (except quotes,
             # to prefer { "x y": 1 } over { :"x y" => 1 }).
             !/[\p{Alnum}"']\z/.match?(sym_name)
            return false
          end

          # Most hash keys can be matched against a simple regex.
          return true if /\A[_a-z]\w*[?!]?\z/i.match?(sym_name)

          return false if target_ruby_version <= 2.1

          (sym_name.start_with?("'") && sym_name.end_with?("'")) ||
            (sym_name.start_with?('"') && sym_name.end_with?('"'))
        end
        # rubocop:enable Metrics/CyclomaticComplexity

        def check(pairs, delim, msg)
          pairs.each do |pair|
            if pair.delimiter == delim
              location = pair.source_range.begin.join(pair.loc.operator)
              add_offense(location, message: msg) do |corrector|
                autocorrect(corrector, pair)

                opposite_style_detected
              end
            else
              correct_style_detected
            end
          end
        end

        def autocorrect_ruby19(corrector, pair_node)
          range = range_for_autocorrect_ruby19(pair_node)

          space = argument_without_space?(pair_node.parent) ? ' ' : ''

          corrector.replace(range, range.source.sub(/^:(.*\S)\s*=>\s*$/, "#{space}\\1: "))

          hash_node = pair_node.parent
          return unless hash_node.parent&.return_type? && !hash_node.braces?

          corrector.wrap(hash_node, '{', '}')
        end

        def range_for_autocorrect_ruby19(pair_node)
          key = pair_node.key.source_range
          operator = pair_node.loc.operator

          range = key.join(operator)
          range_with_surrounding_space(range, side: :right)
        end

        def argument_without_space?(node)
          return false if !node.argument? || !node.parent.loc.selector

          node.source_range.begin_pos == node.parent.loc.selector.end_pos
        end

        def autocorrect_hash_rockets(corrector, pair_node)
          op = pair_node.loc.operator

          key_with_hash_rocket = ":#{pair_node.key.source}#{pair_node.inverse_delimiter(true)}"
          key_with_hash_rocket += pair_node.key.source if pair_node.value_omission?
          corrector.replace(pair_node.key, key_with_hash_rocket)
          corrector.remove(range_with_surrounding_space(op))
        end

        def autocorrect_no_mixed_keys(corrector, pair_node)
          if pair_node.colon?
            autocorrect_hash_rockets(corrector, pair_node)
          else
            autocorrect_ruby19(corrector, pair_node)
          end
        end

        def force_hash_rockets?(pairs)
          cop_config['UseHashRocketsWithSymbolValues'] && pairs.map(&:value).any?(&:sym_type?)
        end
      end
    end
  end
end
