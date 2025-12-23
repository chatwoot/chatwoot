# frozen_string_literal: true

module RuboCop
  module Cop
    module Layout
      # Check that the keys, separators, and values of a multi-line hash
      # literal are aligned according to configuration. The configuration
      # options are:
      #
      # * key (left align keys, one space before hash rockets and values)
      # * separator (align hash rockets and colons, right align keys)
      # * table (left align keys, hash rockets, and values)
      #
      # The treatment of hashes passed as the last argument to a method call
      # can also be configured. The options are:
      #
      # * always_inspect
      # * always_ignore
      # * ignore_implicit (without curly braces)
      #
      # Alternatively you can specify multiple allowed styles. That's done by
      # passing a list of styles to EnforcedHashRocketStyle and EnforcedColonStyle.
      #
      # @example EnforcedHashRocketStyle: key (default)
      #   # bad
      #   {
      #     :foo => bar,
      #      :ba => baz
      #   }
      #   {
      #     :foo => bar,
      #     :ba  => baz
      #   }
      #
      #   # good
      #   {
      #     :foo => bar,
      #     :ba => baz
      #   }
      #
      # @example EnforcedHashRocketStyle: separator
      #   # bad
      #   {
      #     :foo => bar,
      #     :ba => baz
      #   }
      #   {
      #     :foo => bar,
      #     :ba  => baz
      #   }
      #
      #   # good
      #   {
      #     :foo => bar,
      #      :ba => baz
      #   }
      #
      # @example EnforcedHashRocketStyle: table
      #   # bad
      #   {
      #     :foo => bar,
      #      :ba => baz
      #   }
      #
      #   # good
      #   {
      #     :foo => bar,
      #     :ba  => baz
      #   }
      #
      # @example EnforcedColonStyle: key (default)
      #   # bad
      #   {
      #     foo: bar,
      #      ba: baz
      #   }
      #   {
      #     foo: bar,
      #     ba:  baz
      #   }
      #
      #   # good
      #   {
      #     foo: bar,
      #     ba: baz
      #   }
      #
      # @example EnforcedColonStyle: separator
      #   # bad
      #   {
      #     foo: bar,
      #     ba: baz
      #   }
      #
      #   # good
      #   {
      #     foo: bar,
      #      ba: baz
      #   }
      #
      # @example EnforcedColonStyle: table
      #   # bad
      #   {
      #     foo: bar,
      #     ba: baz
      #   }
      #
      #   # good
      #   {
      #     foo: bar,
      #     ba:  baz
      #   }
      #
      # @example EnforcedLastArgumentHashStyle: always_inspect (default)
      #   # Inspect both implicit and explicit hashes.
      #
      #   # bad
      #   do_something(foo: 1,
      #     bar: 2)
      #
      #   # bad
      #   do_something({foo: 1,
      #     bar: 2})
      #
      #   # good
      #   do_something(foo: 1,
      #                bar: 2)
      #
      #   # good
      #   do_something(
      #     foo: 1,
      #     bar: 2
      #   )
      #
      #   # good
      #   do_something({foo: 1,
      #                 bar: 2})
      #
      #   # good
      #   do_something({
      #     foo: 1,
      #     bar: 2
      #   })
      #
      # @example EnforcedLastArgumentHashStyle: always_ignore
      #   # Ignore both implicit and explicit hashes.
      #
      #   # good
      #   do_something(foo: 1,
      #     bar: 2)
      #
      #   # good
      #   do_something({foo: 1,
      #     bar: 2})
      #
      # @example EnforcedLastArgumentHashStyle: ignore_implicit
      #   # Ignore only implicit hashes.
      #
      #   # bad
      #   do_something({foo: 1,
      #     bar: 2})
      #
      #   # good
      #   do_something(foo: 1,
      #     bar: 2)
      #
      # @example EnforcedLastArgumentHashStyle: ignore_explicit
      #   # Ignore only explicit hashes.
      #
      #   # bad
      #   do_something(foo: 1,
      #     bar: 2)
      #
      #   # good
      #   do_something({foo: 1,
      #     bar: 2})
      #
      class HashAlignment < Base
        include HashAlignmentStyles
        include RangeHelp
        extend AutoCorrector

        MESSAGES = {
          KeyAlignment => 'Align the keys of a hash literal if they span more than one line.',
          SeparatorAlignment => 'Align the separators of a hash literal if they span more than ' \
                                'one line.',
          TableAlignment => 'Align the keys and values of a hash literal if they span more than ' \
                            'one line.',
          KeywordSplatAlignment => 'Align keyword splats with the rest of the hash if it spans ' \
                                   'more than one line.'
        }.freeze

        SEPARATOR_ALIGNMENT_STYLES = %w[EnforcedColonStyle EnforcedHashRocketStyle].freeze

        def on_send(node)
          return if double_splat?(node)
          return unless node.arguments?

          last_argument = node.last_argument

          return unless last_argument.hash_type? && ignore_hash_argument?(last_argument)

          ignore_node(last_argument)
        end
        alias on_csend on_send
        alias on_super on_send
        alias on_yield on_send

        def on_hash(node)
          return if autocorrect_incompatible_with_other_cops?(node) || ignored_node?(node) ||
                    node.pairs.empty? || node.single_line?

          proc = ->(a) { a.checkable_layout?(node) }
          return unless alignment_for_hash_rockets.any?(proc) && alignment_for_colons.any?(proc)

          check_pairs(node)
        end

        attr_accessor :offenses_by, :column_deltas

        private

        def autocorrect_incompatible_with_other_cops?(node)
          return false unless enforce_first_argument_with_fixed_indentation? &&
                              node.pairs.any? &&
                              node.parent&.call_type?

          left_sibling = argument_before_hash(node)
          parent_loc = node.parent.loc
          selector = left_sibling || parent_loc.selector || parent_loc.expression

          same_line?(selector, node.pairs.first)
        end

        def argument_before_hash(hash_node)
          hash_node.left_sibling.respond_to?(:loc) ? hash_node.left_sibling : nil
        end

        def reset!
          self.offenses_by = {}
          self.column_deltas = Hash.new { |hash, key| hash[key] = {} }
        end

        def double_splat?(node)
          node.children.last.is_a?(Symbol)
        end

        def check_pairs(node)
          first_pair = node.pairs.first
          reset!

          alignment_for(first_pair).each do |alignment|
            delta = alignment.deltas_for_first_pair(first_pair)
            check_delta delta, node: first_pair, alignment: alignment
          end

          node.children.each do |current|
            alignment_for(current).each do |alignment|
              delta = alignment.deltas(first_pair, current)
              check_delta delta, node: current, alignment: alignment
            end
          end

          add_offenses
        end

        def add_offenses
          kwsplat_offenses = offenses_by.delete(KeywordSplatAlignment)
          register_offenses_with_format(kwsplat_offenses, KeywordSplatAlignment)

          format, offenses = offenses_by.min_by { |_, v| v.length }
          register_offenses_with_format(offenses, format)
        end

        def register_offenses_with_format(offenses, format)
          (offenses || []).each do |offense|
            add_offense(offense, message: MESSAGES[format]) do |corrector|
              delta = column_deltas[alignment_for(offense).first.class][offense]

              correct_node(corrector, offense, delta) unless delta.nil?
            end
          end
        end

        def check_delta(delta, node:, alignment:)
          offenses_by[alignment.class] ||= []
          return if good_alignment? delta

          column_deltas[alignment.class][node] = delta
          offenses_by[alignment.class].push(node)
        end

        def ignore_hash_argument?(node)
          case cop_config['EnforcedLastArgumentHashStyle']
          when 'always_inspect'  then false
          when 'always_ignore'   then true
          when 'ignore_explicit' then node.braces?
          when 'ignore_implicit' then !node.braces?
          end
        end

        def alignment_for(pair)
          if pair.kwsplat_type?
            [KeywordSplatAlignment.new]
          elsif pair.hash_rocket?
            alignment_for_hash_rockets
          else
            alignment_for_colons
          end
        end

        def alignment_for_hash_rockets
          @alignment_for_hash_rockets ||= new_alignment('EnforcedHashRocketStyle')
        end

        def alignment_for_colons
          @alignment_for_colons ||= new_alignment('EnforcedColonStyle')
        end

        def correct_node(corrector, node, delta)
          # We can't use the instance variable inside the lambda. That would
          # just give each lambda the same reference and they would all get the
          # last value of each. A local variable fixes the problem.

          if node.value && node.respond_to?(:value_omission?) && !node.value_omission?
            correct_key_value(corrector, delta, node.key.source_range,
                              node.value.source_range,
                              node.loc.operator)
          else
            delta_value = delta[:key] || 0
            correct_no_value(corrector, delta_value, node.source_range)
          end
        end

        def correct_no_value(corrector, key_delta, key)
          adjust(corrector, key_delta, key)
        end

        def correct_key_value(corrector, delta, key, value, separator)
          # We can't use the instance variable inside the lambda. That would
          # just give each lambda the same reference and they would all get the
          # last value of each. Some local variables fix the problem.
          separator_delta = delta[:separator] || 0
          value_delta     = delta[:value]     || 0
          key_delta       = delta[:key]       || 0

          key_column = key.column
          key_delta = -key_column if key_delta < -key_column

          adjust(corrector, key_delta, key)
          adjust(corrector, separator_delta, separator)
          adjust(corrector, value_delta, value)
        end

        def new_alignment(key)
          formats = cop_config[key]
          formats = [formats] if formats.is_a? String

          formats.uniq.map do |format|
            case format
            when 'key'
              KeyAlignment.new
            when 'table'
              TableAlignment.new
            when 'separator'
              SeparatorAlignment.new
            else
              raise "Unknown #{key}: #{formats}"
            end
          end
        end

        def adjust(corrector, delta, range)
          if delta.positive?
            corrector.insert_before(range, ' ' * delta)
          elsif delta.negative?
            range = range_between(range.begin_pos - delta.abs, range.begin_pos)
            corrector.remove(range)
          end
        end

        def good_alignment?(column_deltas)
          column_deltas.values.all?(&:zero?)
        end

        def enforce_first_argument_with_fixed_indentation?
          argument_alignment_config = config.for_enabled_cop('Layout/ArgumentAlignment')
          argument_alignment_config['EnforcedStyle'] == 'with_fixed_indentation'
        end

        def same_line?(node1, node2)
          # Override `Util#same_line?`
          super || node1.last_line == line(node2)
        end
      end
    end
  end
end
