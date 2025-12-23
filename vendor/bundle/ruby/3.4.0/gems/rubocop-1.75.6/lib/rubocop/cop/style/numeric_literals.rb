# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for big numeric literals without `_` between groups
      # of digits in them.
      #
      # Additional allowed patterns can be added by adding regexps to
      # the `AllowedPatterns` configuration. All regexps are treated
      # as anchored even if the patterns do not contain anchors (so
      # `\d{4}_\d{4}` will allow `1234_5678` but not `1234_5678_9012`).
      #
      # NOTE: Even if `AllowedPatterns` are given, autocorrection will
      # only correct to the standard pattern of an `_` every 3 digits.
      #
      # @example
      #
      #   # bad
      #   1000000
      #   1_00_000
      #   1_0000
      #
      #   # good
      #   1_000_000
      #   1000
      #
      # @example Strict: false (default)
      #
      #   # good
      #   10_000_00 # typical representation of $10,000 in cents
      #
      # @example Strict: true
      #
      #   # bad
      #   10_000_00 # typical representation of $10,000 in cents
      #
      # @example AllowedNumbers: [3000]
      #
      #   # good
      #   3000 # You can specify allowed numbers. (e.g. port number)
      #
      class NumericLiterals < Base
        include IntegerNode
        include AllowedPattern
        extend AutoCorrector

        MSG = 'Use underscores(_) as thousands separator and separate every 3 digits with them.'
        DELIMITER_REGEXP = /[eE.]/.freeze

        # The parameter is called MinDigits (meaning the minimum number of
        # digits for which an offense can be registered), but essentially it's
        # a Max parameter (the maximum number of something that's allowed).
        exclude_limit 'MinDigits'

        def on_int(node)
          check(node)
        end

        def on_float(node)
          check(node)
        end

        private

        def check(node)
          int = integer_part(node)
          # TODO: handle non-decimal literals as well
          return if int.start_with?('0')
          return if allowed_numbers.include?(int)
          return if matches_allowed_pattern?(int)
          return unless int.size >= min_digits

          case int
          when /^\d+$/
            register_offense(node) { self.min_digits = int.size + 1 }
          when /\d{4}/, short_group_regex
            register_offense(node) { self.config_to_allow_offenses = { 'Enabled' => false } }
          end
        end

        def register_offense(node, &_block)
          add_offense(node) do |corrector|
            yield
            corrector.replace(node, format_number(node))
          end
        end

        def short_group_regex
          cop_config['Strict'] ? /_\d{1,2}(_|$)/ : /_\d{1,2}_/
        end

        def format_number(node)
          source = node.source.gsub(/\s+/, '')
          int_part, additional_part = source.split(DELIMITER_REGEXP, 2)
          formatted_int = format_int_part(int_part)
          delimiter = source[DELIMITER_REGEXP]

          if additional_part
            formatted_int + delimiter + additional_part
          else
            formatted_int
          end
        end

        # @param int_part [String]
        def format_int_part(int_part)
          int_part = Integer(int_part)
          formatted_int = int_part.abs.to_s.reverse.gsub(/...(?=.)/, '\&_').reverse
          formatted_int.insert(0, '-') if int_part.negative?
          formatted_int
        end

        def min_digits
          cop_config['MinDigits']
        end

        def allowed_numbers
          cop_config.fetch('AllowedNumbers', []).map(&:to_s)
        end

        def allowed_patterns
          # Convert the patterns to be anchored
          super.map { |regexp| /\A#{regexp}\z/ }
        end
      end
    end
  end
end
