module Shoulda
  module Matchers
    module Independent
      class DelegateMethodMatcher
        # @private
        class DelegateObjectNotSpecified < StandardError
          def message
            'Delegation needs a target. Use the #to method to define one, e.g.
            `post_office.should delegate(:deliver_mail).to(:mailman)`'.squish
          end
        end
      end
    end
  end
end
