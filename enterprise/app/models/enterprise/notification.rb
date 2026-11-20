module Enterprise::Notification
  def fcm_push_data
    data = super
    data[:call] = missed_call_push_data if voice_call_missed?
    data
  end

  def push_message_title
    return super unless voice_call_missed?

    I18n.t('notifications.notification_title.voice_call_missed', inbox_name: primary_actor.inbox.name)
  end

  def push_message_body
    return super unless voice_call_missed?

    missed_call_body
  end

  private

  def missed_call_body
    contact = conversation.contact
    [contact&.name, contact&.phone_number].compact_blank.join(' · ')
  end

  def missed_call_push_data
    call = secondary_actor.try(:call)
    return if call.blank?

    call.push_event_data.slice(:id, :provider_call_id, :provider, :status, :from_number)
  end
end
