# A missed call is recorded for the agents it rang, once, as its own notification type
class Voice::MissedCallNotificationJob < ApplicationJob
  queue_as :default

  def perform(call_id)
    call = Call.find_by(id: call_id)
    return if call.blank? || !call.incoming? || call.status != 'no_answer' || call.message.blank?

    recipients(call).each do |user|
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

  private

  # The agents the ring went to, as recorded when it was sent; a reassignment since then
  # does not change who missed the call. A call with none recorded rang nobody's phone.
  def recipients(call)
    call.account.users.where(id: call.ring_state.fetch('ring_recipient_ids', []))
  end
end
