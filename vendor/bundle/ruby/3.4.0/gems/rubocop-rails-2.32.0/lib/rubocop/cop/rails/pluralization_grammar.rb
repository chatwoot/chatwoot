# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Checks for correct grammar when using ActiveSupport's
      # core extensions to the numeric classes.
      #
      # @example
      #   # bad
      #   3.day.ago
      #   1.months.ago
      #   5.megabyte
      #   1.gigabytes
      #
      #   # good
      #   3.days.ago
      #   1.month.ago
      #   5.megabytes
      #   1.gigabyte
      class PluralizationGrammar < Base
        extend AutoCorrector

        SINGULAR_METHODS = {
          second: :seconds,
          minute: :minutes,
          hour: :hours,
          day: :days,
          week: :weeks,
          fortnight: :fortnights,
          month: :months,
          year: :years,
          byte: :bytes,
          kilobyte: :kilobytes,
          megabyte: :megabytes,
          gigabyte: :gigabytes,
          terabyte: :terabytes,
          petabyte: :petabytes,
          exabyte: :exabytes,
          zettabyte: :zettabytes
        }.freeze

        RESTRICT_ON_SEND = SINGULAR_METHODS.keys + SINGULAR_METHODS.values

        PLURAL_METHODS = SINGULAR_METHODS.invert.freeze

        MSG = 'Prefer `%<number>s.%<correct>s`.'

        def on_send(node)
          return unless duration_method?(node.method_name) && literal_number?(node.receiver) && offense?(node)

          number, = *node.receiver

          add_offense(node, message: message(number, node.method_name)) do |corrector|
            method_name = node.loc.selector.source

            corrector.replace(node.loc.selector, correct_method(method_name))
          end
        end

        private

        def message(number, method_name)
          format(MSG, number: number, correct: correct_method(method_name))
        end

        def correct_method(method_name)
          if plural_method?(method_name)
            singularize(method_name)
          else
            pluralize(method_name)
          end
        end

        def offense?(node)
          number, = *node.receiver

          (singular_receiver?(number) && plural_method?(node.method_name)) ||
            (plural_receiver?(number) && singular_method?(node.method_name))
        end

        def plural_method?(method_name)
          method_name.to_s.end_with?('s')
        end

        def singular_method?(method_name)
          !plural_method?(method_name)
        end

        def singular_receiver?(number)
          number.abs == 1
        end

        def plural_receiver?(number)
          !singular_receiver?(number)
        end

        def literal_number?(node)
          node&.type?(:int, :float)
        end

        def pluralize(method_name)
          SINGULAR_METHODS.fetch(method_name.to_sym).to_s
        end

        def singularize(method_name)
          PLURAL_METHODS.fetch(method_name.to_sym).to_s
        end

        def duration_method?(method_name)
          SINGULAR_METHODS.key?(method_name) || PLURAL_METHODS.key?(method_name)
        end
      end
    end
  end
end
