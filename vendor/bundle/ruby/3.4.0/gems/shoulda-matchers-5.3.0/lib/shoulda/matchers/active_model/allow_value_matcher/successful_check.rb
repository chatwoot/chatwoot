module Shoulda
  module Matchers
    module ActiveModel
      class AllowValueMatcher
        # @private
        class SuccessfulCheck
          def successful?
            true
          end
        end
      end
    end
  end
end
