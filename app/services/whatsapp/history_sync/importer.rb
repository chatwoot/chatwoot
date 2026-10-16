class Whatsapp::HistorySync::Importer
  Result = Data.define(:messages, :conversations, :progress, :terminal_status)
  MissingHistoricalMessageError = Class.new(StandardError)

  def initialize(event)
    @event = event
    @sync = event.history_sync
  end

  def perform
    return declined_result if history_declined?
    return media_result if media_assets.present?

    history_result
  end

  private

  attr_reader :event, :sync

  def history_result
    messages_count = 0
    conversations_count = 0
    importer = Whatsapp::HistorySync::ThreadImporter.new(sync)

    history_entries.each do |entry|
      Array(entry['threads']).each do |thread|
        messages = Array(thread['messages'])
        next if messages.empty?

        result = importer.perform(thread.fetch('id'), messages)
        messages_count += result[:messages]
        conversations_count += 1 if result[:conversation_created]
      end
    end

    result(messages: messages_count, conversations: conversations_count)
  end

  def media_result
    Whatsapp::HistorySync::MediaImporter.new(sync).perform(media_assets)
    result
  end

  def declined_result
    error = history_entries.flat_map { |entry| Array(entry['errors']) }.first || {}
    sync.update!(
      last_error_code: error['code'].to_s.presence,
      last_error_message: error['message'].presence || error['title'].presence
    )
    result(terminal_status: :not_shared)
  end

  def result(messages: 0, conversations: 0, terminal_status: nil)
    Result.new(
      messages: messages,
      conversations: conversations,
      progress: event.progress.to_i,
      terminal_status: terminal_status
    )
  end

  def history_declined?
    history_entries.any? { |entry| Array(entry['errors']).any? }
  end

  def history_entries
    @history_entries ||= Array(change_value['history'])
  end

  def media_assets
    @media_assets ||= Array(change_value['messages'])
  end

  def change_value
    @change_value ||= event.payload.dig('entry', 0, 'changes', 0, 'value') || {}
  end
end
