module Shoulda
  module Matchers
    module ActiveRecord
      module AssociationMatchers
        # @private
        class InverseOfMatcher
          attr_accessor :missing_option

          def initialize(inverse_of, name)
            @inverse_of = inverse_of
            @name = name
            @missing_option = ''
          end

          def description
            "inverse_of => #{inverse_of}"
          end

          def matches?(subject)
            self.subject = ModelReflector.new(subject, name)

            if option_verifier.correct_for_string?(:inverse_of, inverse_of)
              true
            else
              self.missing_option = "#{name} should have #{description}"
              false
            end
          end

          protected

          attr_accessor :subject, :inverse_of, :name

          def option_verifier
            @_option_verifier ||= OptionVerifier.new(subject)
          end
        end
      end
    end
  end
end
