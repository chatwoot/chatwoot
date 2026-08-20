class Whatsapp::HistorySync::RequestService
  def initialize(channel)
    @channel = channel
  end

  def perform
    sync = create_sync
    return sync unless sync.previously_new_record?

    response = api_client.request_history_sync(phone_number_id)
    sync.update!(
      request_id: response['request_id'],
      started_at: Time.current,
      status: :requested
    )
    sync
  rescue StandardError => e
    sync&.update!(status: :failed, last_error_message: e.message, started_at: Time.current)
    raise
  end

  private

  attr_reader :channel

  def create_sync
    existing = WhatsappHistorySync.find_by(whatsapp_channel_id: channel.id)
    return existing if existing

    channel.create_whatsapp_history_sync!(status: :requested)
  rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
    WhatsappHistorySync.find_by!(whatsapp_channel_id: channel.id)
  end

  def api_client
    @api_client ||= Whatsapp::FacebookApiClient.new(channel.provider_config['api_key'])
  end

  def phone_number_id
    channel.provider_config.fetch('phone_number_id')
  end
end
