class Voice::MissedCallNotificationJob < ApplicationJob
  queue_as :default

  def perform(call_id)
    call = Call.find_by(id: call_id)
    return if call.blank? || !call.missed? || call.message.blank?

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

  def recipients(call)
    call.account.users.where(id: call.ring_state.fetch('ring_recipient_ids', []))
  end
end
