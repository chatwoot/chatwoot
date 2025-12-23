module Shoulda
  module Matchers
    module ActiveRecord
      module AssociationMatchers
        # @private
        class SourceMatcher
          attr_accessor :missing_option

          def initialize(source, name)
            @source = source
            @name = name
            @missing_option = ''
          end

          def description
            "source => #{source}"
          end

          def matches?(subject)
            self.subject = ModelReflector.new(subject, name)

            if option_verifier.correct_for_string?(:source, source)
              true
            else
              self.missing_option =
                "#{name} should have #{source} as source option"
              false
            end
          end

          protected

          attr_accessor :subject, :source, :name

          def option_verifier
            @_option_verifier ||= OptionVerifier.new(subject)
          end
        end
      end
    end
  end
end
