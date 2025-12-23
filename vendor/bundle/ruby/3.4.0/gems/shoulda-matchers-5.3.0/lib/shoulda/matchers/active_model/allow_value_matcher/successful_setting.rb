module Shoulda
  module Matchers
    module ActiveModel
      class AllowValueMatcher
        # @private
        class SuccessfulSetting
          def successful?
            true
          end
        end
      end
    end
  end
end
