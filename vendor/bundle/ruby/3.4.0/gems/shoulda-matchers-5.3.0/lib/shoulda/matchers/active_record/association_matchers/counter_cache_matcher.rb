module Shoulda
  module Matchers
    module ActiveRecord
      module AssociationMatchers
        # @private
        class CounterCacheMatcher
          attr_accessor :missing_option

          def initialize(counter_cache, name)
            @counter_cache = counter_cache
            @name = name
            @missing_option = ''
          end

          def description
            "counter_cache => #{counter_cache}"
          end

          def matches?(subject)
            self.subject = ModelReflector.new(subject, name)

            if option_verifier.correct_for_string?(
              :counter_cache,
              counter_cache,
            )
              true
            else
              self.missing_option = "#{name} should have #{description}"
              false
            end
          end

          protected

          attr_accessor :subject, :counter_cache, :name

          def option_verifier
            @_option_verifier ||= OptionVerifier.new(subject)
          end
        end
      end
    end
  end
end
