class Webhooks::ZaloOaEventsJob < MutexApplicationJob
  queue_as :low
  # Retry budget (19 × 2s = 38s) must exceed the 30s lock TTL set in `perform`, otherwise a
  # webhook arriving just after the lock is taken can exhaust retries and silently drop its message.
  retry_on LockAcquisitionError, wait: 2.seconds, attempts: 20

  def perform(params = {})
    channel = find_channel(params)
    return if channel.blank? || channel.inbox.blank?

    # Serialize per (inbox, user) so the first event creates the conversation and the rest append.
    # 30s TTL covers the attachment download; the 1s default expires mid-processing.
    key = format(::Redis::Alfred::ZALO_OA_MESSAGE_MUTEX, inbox_id: channel.inbox.id, user_id: user_id(params))
    with_lock(key, 30.seconds) do
      ZaloOa::IncomingMessageService.new(inbox: channel.inbox, params: params.with_indifferent_access).perform
    end
  end

  private

  def find_channel(params)
    oa_id = params['event_name'].to_s.start_with?('user_') ? params.dig('recipient', 'id') : params.dig('sender', 'id')
    Channel::ZaloOa.find_by(oa_id: oa_id.to_s) if oa_id.present?
  end

  def user_id(params)
    params['event_name'].to_s.start_with?('user_') ? params.dig('sender', 'id') : params.dig('recipient', 'id')
  end
end
