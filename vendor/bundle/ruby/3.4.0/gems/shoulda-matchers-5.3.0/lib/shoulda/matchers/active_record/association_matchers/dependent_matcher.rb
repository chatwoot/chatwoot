module Shoulda
  module Matchers
    module ActiveRecord
      module AssociationMatchers
        # @private
        class DependentMatcher
          attr_accessor :missing_option

          def initialize(dependent, name)
            @dependent = dependent
            @name = name
            @missing_option = ''
          end

          def description
            "dependent => #{dependent}"
          end

          def matches?(subject)
            self.subject = ModelReflector.new(subject, name)

            if option_matches?
              true
            else
              self.missing_option = generate_missing_option
              false
            end
          end

          protected

          attr_accessor :subject, :dependent, :name

          private

          def option_verifier
            @_option_verifier ||= OptionVerifier.new(subject)
          end

          def option_matches?
            option_verifier.correct_for?(option_type, :dependent, dependent)
          end

          def option_type
            case dependent
            when true, false then :boolean
            else :string
            end
          end

          def generate_missing_option
            [
              "#{name} should have",
              (dependent == true ? 'a' : dependent),
              'dependency',
            ].join(' ')
          end
        end
      end
    end
  end
end
