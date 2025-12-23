# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
module RuboCop
  module Cop
    module Style
      # Check for uses of braces or do/end around single line or
      # multi-line blocks.
      #
      # Methods that can be either procedural or functional and cannot be
      # categorised from their usage alone is ignored.
      # `lambda`, `proc`, and `it` are their defaults.
      # Additional methods can be added to the `AllowedMethods`.
      #
      # @example EnforcedStyle: line_count_based (default)
      #   # bad - single line block
      #   items.each do |item| item / 5 end
      #
      #   # good - single line block
      #   items.each { |item| item / 5 }
      #
      #   # bad - multi-line block
      #   things.map { |thing|
      #     something = thing.some_method
      #     process(something)
      #   }
      #
      #   # good - multi-line block
      #   things.map do |thing|
      #     something = thing.some_method
      #     process(something)
      #   end
      #
      # @example EnforcedStyle: semantic
      #   # Prefer `do...end` over `{...}` for procedural blocks.
      #
      #   # return value is used/assigned
      #   # bad
      #   foo = map do |x|
      #     x
      #   end
      #   puts (map do |x|
      #     x
      #   end)
      #
      #   # return value is not used out of scope
      #   # good
      #   map do |x|
      #     x
      #   end
      #
      #   # Prefer `{...}` over `do...end` for functional blocks.
      #
      #   # return value is not used out of scope
      #   # bad
      #   each { |x|
      #     x
      #   }
      #
      #   # return value is used/assigned
      #   # good
      #   foo = map { |x|
      #     x
      #   }
      #   map { |x|
      #     x
      #   }.inspect
      #
      #   # The AllowBracesOnProceduralOneLiners option is allowed unless the
      #   # EnforcedStyle is set to `semantic`. If so:
      #
      #   # If the AllowBracesOnProceduralOneLiners option is unspecified, or
      #   # set to `false` or any other falsey value, then semantic purity is
      #   # maintained, so one-line procedural blocks must use do-end, not
      #   # braces.
      #
      #   # bad
      #   collection.each { |element| puts element }
      #
      #   # good
      #   collection.each do |element| puts element end
      #
      #   # If the AllowBracesOnProceduralOneLiners option is set to `true`, or
      #   # any other truthy value, then one-line procedural blocks may use
      #   # either style. (There is no setting for requiring braces on them.)
      #
      #   # good
      #   collection.each { |element| puts element }
      #
      #   # also good
      #   collection.each do |element| puts element end
      #
      # @example EnforcedStyle: braces_for_chaining
      #   # bad
      #   words.each do |word|
      #     word.flip.flop
      #   end.join("-")
      #
      #   # good
      #   words.each { |word|
      #     word.flip.flop
      #   }.join("-")
      #
      # @example EnforcedStyle: always_braces
      #   # bad
      #   words.each do |word|
      #     word.flip.flop
      #   end
      #
      #   # good
      #   words.each { |word|
      #     word.flip.flop
      #   }
      #
      # @example BracesRequiredMethods: ['sig']
      #
      #   # Methods listed in the BracesRequiredMethods list, such as 'sig'
      #   # in this example, will require `{...}` braces. This option takes
      #   # precedence over all other configurations except AllowedMethods.
      #
      #   # bad
      #   sig do
      #     params(
      #       foo: string,
      #     ).void
      #   end
      #   def bar(foo)
      #     puts foo
      #   end
      #
      #   # good
      #   sig {
      #     params(
      #       foo: string,
      #     ).void
      #   }
      #   def bar(foo)
      #     puts foo
      #   end
      #
      # @example AllowedMethods: ['lambda', 'proc', 'it' ] (default)
      #
      #   # good
      #   foo = lambda do |x|
      #     puts "Hello, #{x}"
      #   end
      #
      #   foo = lambda do |x|
      #     x * 100
      #   end
      #
      # @example AllowedPatterns: [] (default)
      #
      #   # bad
      #   things.map { |thing|
      #     something = thing.some_method
      #     process(something)
      #   }
      #
      # @example AllowedPatterns: ['map']
      #
      #   # good
      #   things.map { |thing|
      #     something = thing.some_method
      #     process(something)
      #   }
      #
      class BlockDelimiters < Base
        include ConfigurableEnforcedStyle
        include AllowedMethods
        include AllowedPattern
        include RangeHelp
        extend AutoCorrector

        ALWAYS_BRACES_MESSAGE = 'Prefer `{...}` over `do...end` for blocks.'

        BRACES_REQUIRED_MESSAGE = "Brace delimiters `{...}` required for '%<method_name>s' method."

        def self.autocorrect_incompatible_with
          [Style::RedundantBegin]
        end

        def on_send(node)
          return unless node.arguments?
          return if node.parenthesized?
          return if node.assignment_method?
          return if single_argument_operator_method?(node)

          node.arguments.each do |arg|
            get_blocks(arg) do |block|
              # If there are no parentheses around the arguments, then braces
              # and do-end have different meaning due to how they bind, so we
              # allow either.
              ignore_node(block)
            end
          end
        end
        alias on_csend on_send

        def on_block(node)
          return if ignored_node?(node)
          return if proper_block_style?(node)

          message = message(node)
          add_offense(node.loc.begin, message: message) do |corrector|
            autocorrect(corrector, node)
          end
        end

        alias on_numblock on_block
        alias on_itblock on_block

        private

        def autocorrect(corrector, node)
          return if correction_would_break_code?(node)

          if node.braces?
            replace_braces_with_do_end(corrector, node.loc)
          else
            replace_do_end_with_braces(corrector, node)
          end
        end

        def line_count_based_message(node)
          if node.multiline?
            'Avoid using `{...}` for multi-line blocks.'
          else
            'Prefer `{...}` over `do...end` for single-line blocks.'
          end
        end

        def semantic_message(node)
          block_begin = node.loc.begin.source

          if block_begin == '{'
            'Prefer `do...end` over `{...}` for procedural blocks.'
          else
            'Prefer `{...}` over `do...end` for functional blocks.'
          end
        end

        def braces_for_chaining_message(node)
          if node.multiline?
            if node.chained?
              'Prefer `{...}` over `do...end` for multi-line chained blocks.'
            else
              'Prefer `do...end` for multi-line blocks without chaining.'
            end
          else
            'Prefer `{...}` over `do...end` for single-line blocks.'
          end
        end

        def braces_required_message(node)
          format(BRACES_REQUIRED_MESSAGE, method_name: node.method_name.to_s)
        end

        def message(node)
          return braces_required_message(node) if braces_required_method?(node.method_name)

          case style
          when :line_count_based    then line_count_based_message(node)
          when :semantic            then semantic_message(node)
          when :braces_for_chaining then braces_for_chaining_message(node)
          when :always_braces       then ALWAYS_BRACES_MESSAGE
          end
        end

        def replace_braces_with_do_end(corrector, loc)
          b = loc.begin
          e = loc.end

          corrector.insert_before(b, ' ') unless whitespace_before?(b)
          corrector.insert_before(e, ' ') unless whitespace_before?(e)
          corrector.insert_after(b, ' ') unless whitespace_after?(b)
          corrector.replace(b, 'do')

          if (comment = processed_source.comment_at_line(e.line))
            move_comment_before_block(corrector, comment, loc.node, e)
          end

          corrector.replace(e, 'end')
        end

        def replace_do_end_with_braces(corrector, node)
          loc = node.loc
          b = loc.begin
          e = loc.end

          corrector.insert_after(b, ' ') unless whitespace_after?(b, 2)

          corrector.replace(b, '{')
          corrector.replace(e, '}')

          corrector.wrap(node.body, "begin\n", "\nend") if begin_required?(node)
        end

        def whitespace_before?(range)
          /\s/.match?(range.source_buffer.source[range.begin_pos - 1, 1])
        end

        def whitespace_after?(range, length = 1)
          /\s/.match?(range.source_buffer.source[range.begin_pos + length, 1])
        end

        def move_comment_before_block(corrector, comment, block_node, closing_brace)
          range = block_node.chained? ? end_of_chain(block_node.parent).source_range : closing_brace

          # It is possible that there is code between the block and the comment
          # which needs to be preserved and trimmed.
          pre_comment_range = source_range_before_comment(range, comment)

          corrector.remove(range_with_surrounding_space(comment.source_range, side: :right))
          remove_trailing_whitespace(corrector, pre_comment_range, comment)
          corrector.insert_after(pre_comment_range, "\n")

          corrector.insert_before(block_node, "#{comment.text}\n")
        end

        def source_range_before_comment(range, comment)
          range = range.end.join(comment.source_range.begin)

          # End the range before any whitespace that precedes the comment
          trailing_whitespace_count = range.source[/\s+\z/]&.length
          range = range.adjust(end_pos: -trailing_whitespace_count) if trailing_whitespace_count

          range
        end

        def end_of_chain(node)
          return end_of_chain(node.block_node) if with_block?(node)
          return node unless node.chained?

          end_of_chain(node.parent)
        end

        def remove_trailing_whitespace(corrector, range, comment)
          range_of_trailing = range.end.join(comment.source_range.begin)

          corrector.remove(range_of_trailing) if range_of_trailing.source.match?(/\A\s+\z/)
        end

        def with_block?(node)
          node.respond_to?(:block_node) && node.block_node
        end

        # rubocop:disable Metrics/CyclomaticComplexity
        def get_blocks(node, &block)
          case node.type
          when :block, :numblock, :itblock
            yield node
          when :send, :csend
            # When a method has an argument which is another method with a block,
            # that block needs braces, otherwise a syntax error will be introduced
            # for subsequent arguments.
            # Additionally, even without additional arguments, changing `{...}` to
            # `do...end` will change the binding of the block to the outer method.
            get_blocks(node.receiver, &block) if node.receiver
            node.arguments.each { |argument| get_blocks(argument, &block) }
          when :hash
            # A hash which is passed as method argument may have no braces
            # In that case, one of the K/V pairs could contain a block node
            # which could change in meaning if `do...end` is replaced with `{...}`
            return if node.braces?

            node.each_child_node { |child| get_blocks(child, &block) }
          when :pair
            node.each_child_node { |child| get_blocks(child, &block) }
          end
        end
        # rubocop:enable Metrics/CyclomaticComplexity

        def proper_block_style?(node)
          return true if require_do_end?(node)
          return special_method_proper_block_style?(node) if special_method?(node.method_name)

          case style
          when :line_count_based    then line_count_based_block_style?(node)
          when :semantic            then semantic_block_style?(node)
          when :braces_for_chaining then braces_for_chaining_style?(node)
          when :always_braces       then braces_style?(node)
          end
        end

        def require_do_end?(node)
          return false if node.braces? || node.multiline?
          return false unless (resbody = node.each_descendant(:resbody).first)

          resbody.children.first&.array_type?
        end

        def special_method?(method_name)
          allowed_method?(method_name) ||
            matches_allowed_pattern?(method_name) ||
            braces_required_method?(method_name)
        end

        def special_method_proper_block_style?(node)
          method_name = node.method_name
          return true if allowed_method?(method_name) || matches_allowed_pattern?(method_name)

          node.braces? if braces_required_method?(method_name)
        end

        def braces_required_method?(method_name)
          braces_required_methods.include?(method_name.to_s)
        end

        def braces_required_methods
          cop_config.fetch('BracesRequiredMethods', [])
        end

        def line_count_based_block_style?(node)
          node.multiline? ^ node.braces?
        end

        def semantic_block_style?(node)
          method_name = node.method_name

          if node.braces?
            functional_method?(method_name) || functional_block?(node) ||
              (procedural_oneliners_may_have_braces? && !node.multiline?)
          else
            procedural_method?(method_name) || !return_value_used?(node)
          end
        end

        def braces_for_chaining_style?(node)
          block_begin = node.loc.begin.source

          block_begin == if node.multiline?
                           (node.chained? ? '{' : 'do')
                         else
                           '{'
                         end
        end

        def braces_style?(node)
          node.loc.begin.source == '{'
        end

        def correction_would_break_code?(node)
          return false unless node.keywords?

          node.send_node.arguments? && !node.send_node.parenthesized?
        end

        def functional_method?(method_name)
          cop_config['FunctionalMethods'].map(&:to_sym).include?(method_name)
        end

        def functional_block?(node)
          return_value_used?(node) || return_value_of_scope?(node)
        end

        def procedural_oneliners_may_have_braces?
          cop_config['AllowBracesOnProceduralOneLiners']
        end

        def procedural_method?(method_name)
          cop_config['ProceduralMethods'].map(&:to_sym).include?(method_name)
        end

        def return_value_used?(node)
          return false unless node.parent

          # If there are parentheses around the block, check if that
          # is being used.
          if node.parent.begin_type?
            return_value_used?(node.parent)
          else
            node.parent.assignment? || node.parent.call_type?
          end
        end

        def return_value_of_scope?(node)
          return false unless (parent = node.parent)

          parent.conditional? || parent.operator_keyword? || array_or_range?(parent) ||
            parent.children.last == node
        end

        def array_or_range?(node)
          node.type?(:array, :range)
        end

        def begin_required?(block_node)
          # If the block contains `rescue` or `ensure`, it needs to be wrapped in
          # `begin`...`end` when changing `do-end` to `{}`.
          block_node.each_child_node(:rescue, :ensure).any? && !block_node.single_line?
        end

        def single_argument_operator_method?(node)
          return false unless node.operator_method?

          node.arguments.one? && node.first_argument.block_type?
        end
      end
    end
  end
end
# rubocop:enable Metrics/ClassLength
