# A ringing inbound call holds off its conversation's auto-assignment, so the agent who answers gets it;
# see Enterprise::Conversation#call_ringing?
module Concerns::CallAssignmentHold
  extend ActiveSupport::Concern

  included do
    # A call still ringing past Twilio's dial limit lost its end callback, so it holds nothing
    scope :holding_assignment, lambda {
      incoming.where(status: 'ringing', created_at: Voice::RingNextAgentJob::MAX_RING_SECONDS.seconds.ago..)
    }

    after_update_commit -> { conversation.auto_assign_after_call },
                        if: -> { incoming? && terminal? && status_before_last_save == 'ringing' }
  end
end
