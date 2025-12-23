# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for array literals made up of symbols that are not
      # using the %i() syntax.
      #
      # Alternatively, it checks for symbol arrays using the %i() syntax on
      # projects which do not want to use that syntax, perhaps because they
      # support a version of Ruby lower than 2.0.
      #
      # Configuration option: MinSize
      # If set, arrays with fewer elements than this value will not trigger the
      # cop. For example, a `MinSize` of `3` will not enforce a style on an
      # array of 2 or fewer elements.
      #
      # @example EnforcedStyle: percent (default)
      #   # good
      #   %i[foo bar baz]
      #
      #   # bad
      #   [:foo, :bar, :baz]
      #
      #   # bad (contains spaces)
      #   %i[foo\ bar baz\ quux]
      #
      #   # bad (contains [] with spaces)
      #   %i[foo \[ \]]
      #
      #   # bad (contains () with spaces)
      #   %i(foo \( \))
      #
      # @example EnforcedStyle: brackets
      #   # good
      #   [:foo, :bar, :baz]
      #
      #   # bad
      #   %i[foo bar baz]
      class SymbolArray < Base
        include ArrayMinSize
        include ArraySyntax
        include ConfigurableEnforcedStyle
        include PercentArray
        extend AutoCorrector
        extend TargetRubyVersion

        minimum_target_ruby_version 2.0

        PERCENT_MSG = 'Use `%i` or `%I` for an array of symbols.'
        ARRAY_MSG = 'Use %<prefer>s for an array of symbols.'
        DELIMITERS = ['[', ']', '(', ')'].freeze
        SPECIAL_GVARS = %w[
          $! $" $$ $& $' $* $+ $, $/ $; $: $. $< $= $> $? $@ $\\ $_ $` $~ $0
          $-0 $-F $-I $-K $-W $-a $-d $-i $-l $-p $-v $-w
        ].freeze
        REDEFINABLE_OPERATORS = %w(
          | ^ & <=> == === =~ > >= < <= << >>
          + - * / % ** ~ +@ -@ [] []= ` ! != !~
        ).freeze

        class << self
          attr_accessor :largest_brackets
        end

        def on_array(node)
          if bracketed_array_of?(:sym, node)
            return if complex_content?(node)

            check_bracketed_array(node, 'i')
          elsif node.percent_literal?(:symbol)
            check_percent_array(node)
          end
        end

        private

        def complex_content?(node)
          node.children.any? do |sym|
            return false if DELIMITERS.include?(sym.source)

            content = *sym
            content = content.map { |c| c.is_a?(AST::Node) ? c.source : c }.join
            content_without_delimiter_pairs = content.gsub(/(\[[^\s\[\]]*\])|(\([^\s\(\)]*\))/, '')

            content.include?(' ') || DELIMITERS.any? do |delimiter|
              content_without_delimiter_pairs.include?(delimiter)
            end
          end
        end

        def invalid_percent_array_contents?(node)
          complex_content?(node)
        end

        def build_bracketed_array(node)
          return '[]' if node.children.empty?

          syms = node.children.map do |c|
            if c.dsym_type?
              string_literal = to_string_literal(c.source)

              ":#{trim_string_interpolation_escape_character(string_literal)}"
            else
              to_symbol_literal(c.value.to_s)
            end
          end
          build_bracketed_array_with_appropriate_whitespace(elements: syms, node: node)
        end

        def to_symbol_literal(string)
          if symbol_without_quote?(string)
            ":#{string}"
          else
            ":#{to_string_literal(string)}"
          end
        end

        def symbol_without_quote?(string)
          # method name
          /\A[a-zA-Z_]\w*[!?]?\z/.match?(string) ||
            # instance / class variable
            /\A@@?[a-zA-Z_]\w*\z/.match?(string) ||
            # global variable
            /\A\$[1-9]\d*\z/.match?(string) ||
            /\A\$[a-zA-Z_]\w*\z/.match?(string) ||
            SPECIAL_GVARS.include?(string) ||
            REDEFINABLE_OPERATORS.include?(string)
        end
      end
    end
  end
end
