# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Identifies passing any argument to `#to_s`.
      #
      # @safety
      #   This cop is marked as unsafe because it may detect `#to_s` calls
      #   that are not related to Active Support implementation.
      #
      # @example
      #
      #   # bad
      #   obj.to_s(:delimited)
      #
      #   # good
      #   obj.to_formatted_s(:delimited)
      #
      class ToSWithArgument < Base
        extend AutoCorrector
        extend TargetRailsVersion

        # These types are defined by the following files in ActiveSupport:
        #   lib/active_support/core_ext/array/conversions.rb
        #   lib/active_support/core_ext/date/conversions.rb
        #   lib/active_support/core_ext/date_time/conversions.rb
        #   lib/active_support/core_ext/numeric/conversions.rb
        #   lib/active_support/core_ext/range/conversions.rb
        #   lib/active_support/core_ext/time/conversions.rb
        #   lib/active_support/time_with_zone.rb
        EXTENDED_FORMAT_TYPES = Set.new(
          %i[
            currency
            db
            delimited
            human
            human_size
            inspect
            iso8601
            long
            long_ordinal
            nsec
            number
            percentage
            phone
            rfc822
            rounded
            short
            time
            usec
          ]
        )

        MSG = 'Use `to_formatted_s` instead.'

        RESTRICT_ON_SEND = %i[to_s].freeze

        minimum_target_rails_version 7.0

        def on_send(node)
          return unless rails_extended_to_s?(node)

          add_offense(node.loc.selector) do |corrector|
            corrector.replace(node.loc.selector, 'to_formatted_s')
          end
        end
        alias on_csend on_send

        private

        def rails_extended_to_s?(node)
          node.first_argument&.sym_type? && EXTENDED_FORMAT_TYPES.include?(node.first_argument.value)
        end
      end
    end
  end
end
