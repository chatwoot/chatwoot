# A missed call is recorded for the agents it rang, once, as its own notification type
class Voice::MissedCallNotificationJob < ApplicationJob
  queue_as :default

  def perform(call_id)
    call = Call.find_by(id: call_id)
    return if call.blank? || !call.incoming? || call.status != 'no_answer' || call.message.blank?

    Voice::VoipPushService.recipients_for(call).each do |user|
      next if user.notifications.exists?(notification_type: 'voice_call_missed', secondary_actor: call.message)

      NotificationBuilder.new(
        notification_type: 'voice_call_missed',
        user: user,
        account: call.account,
        primary_actor: call.conversation,
        secondary_actor: call.message
      ).perform
    end
  end
end
