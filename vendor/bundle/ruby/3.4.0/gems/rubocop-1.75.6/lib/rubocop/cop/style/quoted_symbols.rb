# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks if the quotes used for quoted symbols match the configured defaults.
      # By default uses the same configuration as `Style/StringLiterals`; if that
      # cop is not enabled, the default `EnforcedStyle` is `single_quotes`.
      #
      # String interpolation is always kept in double quotes.
      #
      # NOTE: `Lint/SymbolConversion` can be used in parallel to ensure that symbols
      # are not quoted that don't need to be. This cop is for configuring the quoting
      # style to use for symbols that require quotes.
      #
      # @example EnforcedStyle: same_as_string_literals (default) / single_quotes
      #   # bad
      #   :"abc-def"
      #
      #   # good
      #   :'abc-def'
      #   :"#{str}"
      #   :"a\'b"
      #
      # @example EnforcedStyle: double_quotes
      #   # bad
      #   :'abc-def'
      #
      #   # good
      #   :"abc-def"
      #   :"#{str}"
      #   :"a\'b"
      class QuotedSymbols < Base
        include ConfigurableEnforcedStyle
        include SymbolHelp
        include StringLiteralsHelp
        extend AutoCorrector

        MSG_SINGLE = "Prefer single-quoted symbols when you don't need string interpolation " \
                     'or special symbols.'
        MSG_DOUBLE = 'Prefer double-quoted symbols unless you need single quotes to ' \
                     'avoid extra backslashes for escaping.'

        def on_sym(node)
          return unless quoted?(node)

          message = style == :single_quotes ? MSG_SINGLE : MSG_DOUBLE

          if wrong_quotes?(node) || invalid_double_quotes?(node.source)
            add_offense(node, message: message) do |corrector|
              opposite_style_detected
              autocorrect(corrector, node)
            end
          else
            correct_style_detected
          end
        end

        private

        def invalid_double_quotes?(source)
          return false unless style == :double_quotes

          # The string needs single quotes if:
          # 1. It contains a double quote
          # 2. It contains text that would become an escape sequence with double quotes
          # 3. It contains text that would become an interpolation with double quotes
          !/" | (?<!\\)\\[aAbcdefkMnprsStuUxzZ0-7] | \#[@{$]/x.match?(source)
        end

        def autocorrect(corrector, node)
          str = if hash_colon_key?(node)
                  # strip quotes
                  correct_quotes(node.source[1..-2])
                else
                  # strip leading `:` and quotes
                  ":#{correct_quotes(node.source[2..-2])}"
                end

          corrector.replace(node, str)
        end

        def hash_colon_key?(node)
          # Is the node a hash key with the colon style?
          hash_key?(node) && node.parent.colon?
        end

        def correct_quotes(str)
          correction = if style == :single_quotes
                         to_string_literal(str)
                       else
                         str.gsub("\\'", "'").inspect
                       end

          # The conversion process doubles escaped slashes, so they have to be reverted
          correction.gsub('\\\\', '\\').gsub('\"', '"')
        end

        def style
          return super unless super == :same_as_string_literals
          return :single_quotes unless config.cop_enabled?('Style/StringLiterals')

          string_literals_config['EnforcedStyle'].to_sym
        end

        def alternative_style
          (supported_styles - [style, :same_as_string_literals]).first
        end

        def quoted?(sym_node)
          sym_node.source.match?(/\A:?(['"]).*?\1\z/m)
        end

        def wrong_quotes?(node)
          return super if hash_key?(node)

          super(node.source[1..])
        end
      end
    end
  end
end
