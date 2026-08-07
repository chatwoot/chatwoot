class Webhooks::FacebookPostbackJob < MutexApplicationJob
  queue_as :default
  retry_on LockAcquisitionError, wait: 3.seconds, attempts: 10

  def perform(event_json)
    payload = normalize_payload(JSON.parse(event_json).with_indifferent_access)
    sender_id = payload.dig(:sender, :id)
    recipient_id = payload.dig(:recipient, :id)
    return if sender_id.blank? || recipient_id.blank?

    key = format(::Redis::Alfred::FACEBOOK_MESSAGE_MUTEX, sender_id: sender_id, recipient_id: recipient_id)
    with_lock(key) do
      # The same Facebook page can be connected to more than one Chatwoot account,
      # so fan out to every matching page/inbox rather than an arbitrary single one.
      Channel::FacebookPage.where(page_id: recipient_id).find_each do |facebook_channel|
        next if facebook_channel.inbox.blank?

        Messages::Facebook::PostbackBuilder.new(payload, facebook_channel.inbox).perform
      end
    end
  end

  private

  def normalize_payload(payload)
    payload[:messaging].is_a?(Hash) ? payload[:messaging].with_indifferent_access : payload
  end
end
