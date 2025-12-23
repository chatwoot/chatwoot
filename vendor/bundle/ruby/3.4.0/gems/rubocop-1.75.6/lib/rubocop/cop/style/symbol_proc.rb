# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Use symbols as procs when possible.
      #
      # If you prefer a style that allows block for method with arguments,
      # please set `true` to `AllowMethodsWithArguments`.
      # `define_method?` methods are allowed by default.
      # These are customizable with `AllowedMethods` option.
      #
      # @safety
      #   This cop is unsafe because there is a difference that a `Proc`
      #   generated from `Symbol#to_proc` behaves as a lambda, while
      #   a `Proc` generated from a block does not.
      #   For example, a lambda will raise an `ArgumentError` if the
      #   number of arguments is wrong, but a non-lambda `Proc` will not.
      #
      #   For example:
      #
      #   [source,ruby]
      #   ----
      #   class Foo
      #     def bar
      #       :bar
      #     end
      #   end
      #
      #   def call(options = {}, &block)
      #     block.call(Foo.new, options)
      #   end
      #
      #   call { |x| x.bar }
      #   #=> :bar
      #   call(&:bar)
      #   # ArgumentError: wrong number of arguments (given 1, expected 0)
      #   ----
      #
      #   It is also unsafe because `Symbol#to_proc` does not work with
      #   `protected` methods which would otherwise be accessible.
      #
      #   For example:
      #
      #   [source,ruby]
      #   ----
      #   class Box
      #     def initialize
      #       @secret = rand
      #     end
      #
      #     def normal_matches?(*others)
      #       others.map { |other| other.secret }.any?(secret)
      #     end
      #
      #     def symbol_to_proc_matches?(*others)
      #       others.map(&:secret).any?(secret)
      #     end
      #
      #     protected
      #
      #     attr_reader :secret
      #   end
      #
      #   boxes = [Box.new, Box.new]
      #   Box.new.normal_matches?(*boxes)
      #   # => false
      #   boxes.first.normal_matches?(*boxes)
      #   # => true
      #   Box.new.symbol_to_proc_matches?(*boxes)
      #   # => NoMethodError: protected method `secret' called for #<Box...>
      #   boxes.first.symbol_to_proc_matches?(*boxes)
      #   # => NoMethodError: protected method `secret' called for #<Box...>
      #   ----
      #
      # @example
      #   # bad
      #   something.map { |s| s.upcase }
      #   something.map { _1.upcase }
      #
      #   # good
      #   something.map(&:upcase)
      #
      # @example AllowMethodsWithArguments: false (default)
      #   # bad
      #   something.do_something(foo) { |o| o.bar }
      #
      #   # good
      #   something.do_something(foo, &:bar)
      #
      # @example AllowMethodsWithArguments: true
      #   # good
      #   something.do_something(foo) { |o| o.bar }
      #
      # @example AllowComments: false (default)
      #   # bad
      #   something.do_something do |s| # some comment
      #     # some comment
      #     s.upcase # some comment
      #     # some comment
      #   end
      #
      # @example AllowComments: true
      #   # good  - if there are comment in either position
      #   something.do_something do |s| # some comment
      #     # some comment
      #     s.upcase # some comment
      #     # some comment
      #   end
      #
      # @example AllowedMethods: [define_method] (default)
      #   # good
      #   define_method(:foo) { |foo| foo.bar }
      #
      # @example AllowedPatterns: [] (default)
      #   # bad
      #   something.map { |s| s.upcase }
      #
      # @example AllowedPatterns: ['map'] (default)
      #   # good
      #   something.map { |s| s.upcase }
      #
      # @example AllCops:ActiveSupportExtensionsEnabled: false (default)
      #   # bad
      #   ->(x) { x.foo }
      #   proc { |x| x.foo }
      #   Proc.new { |x| x.foo }
      #
      #   # good
      #   lambda(&:foo)
      #   proc(&:foo)
      #   Proc.new(&:foo)
      #
      # @example AllCops:ActiveSupportExtensionsEnabled: true
      #   # good
      #   ->(x) { x.foo }
      #   proc { |x| x.foo }
      #   Proc.new { |x| x.foo }
      #
      class SymbolProc < Base
        include CommentsHelp
        include RangeHelp
        include AllowedMethods
        include AllowedPattern
        extend AutoCorrector

        MSG = 'Pass `&:%<method>s` as an argument to `%<block_method>s` instead of a block.'
        SUPER_TYPES = %i[super zsuper].freeze
        LAMBDA_OR_PROC = %i[lambda proc].freeze

        # @!method proc_node?(node)
        def_node_matcher :proc_node?, '(send (const {nil? cbase} :Proc) :new)'

        # @!method symbol_proc_receiver?(node)
        def_node_matcher :symbol_proc_receiver?, '{(call ...) (super ...) zsuper}'

        # @!method symbol_proc?(node)
        def_node_matcher :symbol_proc?, <<~PATTERN
          {
            (block $#symbol_proc_receiver? $(args (arg _var)) (send (lvar _var) $_))
            (numblock $#symbol_proc_receiver? $1 (send (lvar :_1) $_))
            (itblock $#symbol_proc_receiver? $_ (send (lvar :it) $_))
          }
        PATTERN

        def self.autocorrect_incompatible_with
          [Layout::SpaceBeforeBlockBraces]
        end

        # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        def on_block(node)
          symbol_proc?(node) do |dispatch_node, arguments_node, method_name|
            if active_support_extensions_enabled?
              return if proc_node?(dispatch_node)
              return if LAMBDA_OR_PROC.include?(dispatch_node.method_name)
            end
            return if unsafe_hash_usage?(dispatch_node)
            return if unsafe_array_usage?(dispatch_node)
            return if allowed_method_name?(dispatch_node.method_name)
            return if allow_if_method_has_argument?(node.send_node)
            return if node.block_type? && destructuring_block_argument?(arguments_node)
            return if allow_comments? && contains_comments?(node)

            register_offense(node, method_name, dispatch_node.method_name)
          end
        end
        # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        alias on_numblock on_block
        alias on_itblock on_block

        def destructuring_block_argument?(argument_node)
          argument_node.one? && argument_node.source.include?(',')
        end

        private

        # See: https://github.com/rubocop/rubocop/issues/10864
        def unsafe_hash_usage?(node)
          node.receiver&.hash_type? && %i[reject select].include?(node.method_name)
        end

        def unsafe_array_usage?(node)
          node.receiver&.array_type? && %i[min max].include?(node.method_name)
        end

        def allowed_method_name?(name)
          allowed_method?(name) || matches_allowed_pattern?(name)
        end

        def register_offense(node, method_name, block_method_name)
          block_start = node.loc.begin.begin_pos
          block_end = node.loc.end.end_pos
          range = range_between(block_start, block_end)
          message = format(MSG, method: method_name, block_method: block_method_name)

          add_offense(range, message: message) { |corrector| autocorrect(corrector, node) }
        end

        def autocorrect(corrector, node)
          if node.send_node.arguments?
            autocorrect_with_args(corrector, node, node.send_node.arguments, node.body.method_name)
          else
            autocorrect_without_args(corrector, node)
          end
        end

        def autocorrect_without_args(corrector, node)
          if node.send_node.lambda_literal?
            if node.send_node.loc.selector.source == '->'
              corrector.replace(node, "lambda(&:#{node.body.method_name})")
              return
            else
              autocorrect_lambda_block(corrector, node)
            end
          end

          corrector.replace(block_range_with_space(node), "(&:#{node.body.method_name})")
        end

        def autocorrect_with_args(corrector, node, args, method_name)
          arg_range = args.last.source_range
          arg_range = range_with_surrounding_comma(arg_range, :right)
          replacement = " &:#{method_name}"
          replacement = ",#{replacement}" unless arg_range.source.end_with?(',')
          corrector.insert_after(arg_range, replacement)
          corrector.remove(block_range_with_space(node))
        end

        def autocorrect_lambda_block(corrector, node)
          send_node_loc = node.send_node.loc
          corrector.replace(send_node_loc.selector, 'lambda')

          range = range_between(send_node_loc.selector.end_pos, node.loc.begin.end_pos - 2)
          corrector.remove(range)
        end

        def block_range_with_space(node)
          block_range = range_between(begin_pos_for_replacement(node), node.loc.end.end_pos)
          range_with_surrounding_space(block_range, side: :left)
        end

        def begin_pos_for_replacement(node)
          expr = node.send_node.source_range

          if (paren_pos = (expr.source =~ /\(\s*\)$/))
            expr.begin_pos + paren_pos
          else
            node.loc.begin.begin_pos
          end
        end

        def allow_if_method_has_argument?(send_node)
          !!cop_config.fetch('AllowMethodsWithArguments', false) && !send_node.arguments.count.zero?
        end

        def allow_comments?
          cop_config.fetch('AllowComments', false)
        end
      end
    end
  end
end
