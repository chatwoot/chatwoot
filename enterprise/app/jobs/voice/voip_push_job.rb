class Voice::VoipPushJob < ApplicationJob
  queue_as :critical

  # action: 'ring' when an inbound call starts ringing, 'cancel' when it stops
  def perform(call_id, action)
    call = Call.find_by(id: call_id)
    return if call.blank?

    Voice::VoipPushService.new(call: call).perform(action.to_s)
  end
end
