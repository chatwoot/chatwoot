class Whatsapp::HistorySync::IngestService
  def initialize(channel:, params:)
    @channel = channel
    @payload = params.deep_stringify_keys
  end

  def perform
    sync = history_sync
    event = create_event(sync)
    return event if event.processed? || event.processing?

    sync.update!(
      status: sync.not_shared? || sync.completed? ? sync.status : :receiving,
      progress: [sync.progress, event.progress.to_i].max,
      first_event_at: sync.first_event_at || Time.current
    )
    Whatsapp::HistorySyncEventJob.perform_later(event.id)
    event
  end

  private

  attr_reader :channel, :payload

  def history_sync
    channel.whatsapp_history_sync || channel.create_whatsapp_history_sync!(status: :receiving, first_event_at: Time.current)
  rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
    WhatsappHistorySync.find_by!(whatsapp_channel_id: channel.id)
  end

  def create_event(sync)
    sync.events.create!(
      event_key: event_key,
      payload: payload,
      phase: history_metadata['phase'],
      chunk_order: history_metadata['chunk_order'],
      progress: history_metadata['progress']
    )
  rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
    sync.events.find_by!(event_key: event_key)
  end

  def event_key
    @event_key ||= Digest::SHA256.hexdigest(payload.to_json)
  end

  def history_metadata
    @history_metadata ||= Array(change_value['history']).filter_map { |item| item['metadata'] }.max_by { |item| item['progress'].to_i } || {}
  end

  def change_value
    @change_value ||= payload.dig('entry', 0, 'changes', 0, 'value') || {}
  end
end
