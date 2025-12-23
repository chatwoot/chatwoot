# frozen_string_literal: true

module RuboCop
  module Cop
    module Naming
      # Checks for non-ascii characters in identifier and constant names.
      # Identifiers are always checked and whether constants are checked
      # can be controlled using AsciiConstants config.
      #
      # @example
      #   # bad
      #   def καλημερα # Greek alphabet (non-ascii)
      #   end
      #
      #   # bad
      #   def こんにちはと言う # Japanese character (non-ascii)
      #   end
      #
      #   # bad
      #   def hello_🍣 # Emoji (non-ascii)
      #   end
      #
      #   # good
      #   def say_hello
      #   end
      #
      #   # bad
      #   신장 = 10 # Hangul character (non-ascii)
      #
      #   # good
      #   height = 10
      #
      #   # bad
      #   params[:عرض_gteq] # Arabic character (non-ascii)
      #
      #   # good
      #   params[:width_gteq]
      #
      # @example AsciiConstants: true (default)
      #   # bad
      #   class Foö
      #   end
      #
      #   FOÖ = "foo"
      #
      # @example AsciiConstants: false
      #   # good
      #   class Foö
      #   end
      #
      #   FOÖ = "foo"
      #
      class AsciiIdentifiers < Base
        include RangeHelp

        IDENTIFIER_MSG = 'Use only ascii symbols in identifiers.'
        CONSTANT_MSG   = 'Use only ascii symbols in constants.'

        def on_new_investigation
          processed_source.tokens.each do |token|
            next if !should_check?(token) || token.text.ascii_only?

            message = token.type == :tIDENTIFIER ? IDENTIFIER_MSG : CONSTANT_MSG
            add_offense(first_offense_range(token), message: message)
          end
        end

        private

        def should_check?(token)
          token.type == :tIDENTIFIER || (token.type == :tCONSTANT && cop_config['AsciiConstants'])
        end

        def first_offense_range(identifier)
          expression    = identifier.pos
          first_offense = first_non_ascii_chars(identifier.text)

          start_position = expression.begin_pos + identifier.text.index(first_offense)
          end_position   = start_position + first_offense.length

          range_between(start_position, end_position)
        end

        def first_non_ascii_chars(string)
          string.match(/[^[:ascii:]]+/).to_s
        end
      end
    end
  end
end
