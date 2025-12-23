module Shoulda
  module Matchers
    module ActiveModel
      class ValidationMatcher
        # @private
        class BuildDescription
          def self.call(matcher, main_description)
            new(matcher, main_description).call
          end

          def initialize(matcher, main_description)
            @matcher = matcher
            @main_description = main_description
          end

          def call
            if description_clauses_for_qualifiers.any?
              "#{main_description}#{clause_for_allow_blank_or_nil},"\
              " #{description_clauses_for_qualifiers.to_sentence}"
            else
              main_description + clause_for_allow_blank_or_nil
            end
          end

          protected

          attr_reader :matcher, :main_description

          private

          def clause_for_allow_blank_or_nil
            if matcher.try(:expects_to_allow_blank?)
              ' as long as it is not blank'
            elsif matcher.try(:expects_to_allow_nil?)
              ' as long as it is not nil'
            else
              ''
            end
          end

          def description_clauses_for_qualifiers
            description_clauses = []

            if matcher.try(:expects_strict?)
              description_clauses << 'raising a validation exception'

              if matcher.try(:expects_custom_validation_message?)
                description_clauses.last << ' with a custom message'
              end

              description_clauses.last << ' on failure'
            elsif matcher.try(:expects_custom_validation_message?)
              description_clauses <<
                'producing a custom validation error on failure'
            end

            description_clauses
          end
        end
      end
    end
  end
end
