module Facebook
  module Messenger
    module Incoming
      # The PolicyEnforcement class represents an incoming webhook response from
      # Facebook when they are notifying your app of a policy violation
      #
      # https://developers.facebook.com/docs/messenger-platform/reference/webhook-events/messaging_policy_enforcement
      class PolicyEnforcement
        include Facebook::Messenger::Incoming::Common

        def action
          @messaging['policy_enforcement']['action']
        end

        def reason
          @messaging['policy_enforcement']['reason']
        end
      end
    end
  end
end
