class Whatsapp::HistorySync::MessageBuilder
  HISTORY_SOURCE = 'whatsapp_history_sync'.freeze
  MEDIA_TYPES = %w[audio document image sticker video voice].freeze
  CONTENT_BUILDERS = {
    'button' => :button_content,
    'interactive' => :interactive_content,
    'location' => :location_content,
    'media_placeholder' => :history_media_copy,
    'text' => :text_content
  }.freeze
  STATUS_MAP = {
    'DELIVERED' => :delivered,
    'ERROR' => :failed,
    'PENDING' => :sent,
    'PLAYED' => :read,
    'READ' => :read,
    'SENT' => :sent
  }.freeze

  def initialize(sync, conversation)
    @sync = sync
    @channel = sync.channel
    @inbox = @channel.inbox
    @conversation = conversation
  end

  def perform(message)
    source_id = message.fetch('id').to_s
    return if Message.exists?(source_id: source_id)
    return unless Whatsapp::MessageDedupLock.new(source_id).acquire!

    build_attributes(message, source_id)
  end

  private

  attr_reader :sync, :channel, :inbox, :conversation

  def build_attributes(message, source_id)
    direction = message_direction(message)
    content = message_content(message).to_s.truncate(150_000)
    timestamp = Time.zone.at(Integer(message.fetch('timestamp')))
    message_record_attributes(message, source_id, direction, content, timestamp)
  end

  def message_record_attributes(message, source_id, direction, content, timestamp)
    {
      account_id: inbox.account_id,
      inbox_id: inbox.id,
      conversation_id: conversation.id,
      message_type: Message.message_types.fetch(direction),
      content_type: Message.content_types[:text],
      content: content,
      processed_message_content: content,
      private: false,
      status: Message.statuses.fetch(message_status(message)),
      sender_type: direction == :incoming ? 'Contact' : nil,
      sender_id: direction == :incoming ? conversation.contact_id : nil,
      source_id: source_id,
      content_attributes: content_attributes(direction),
      additional_attributes: additional_attributes(message),
      created_at: timestamp,
      updated_at: timestamp
    }
  end

  def content_attributes(direction)
    attributes = { historical: true }
    attributes[:external_echo] = true if direction == :outgoing
    attributes
  end

  def additional_attributes(message)
    {
      source: HISTORY_SOURCE,
      whatsapp_history_sync_id: sync.id,
      whatsapp_history_status: message.dig('history_context', 'status')
    }.compact
  end

  def message_direction(message)
    message['from'].to_s.gsub(/\D/, '') == channel.phone_number.to_s.gsub(/\D/, '') ? :outgoing : :incoming
  end

  def message_status(message)
    STATUS_MAP.fetch(message.dig('history_context', 'status').to_s.upcase, :sent)
  end

  def message_content(message)
    type = message['type'].to_s
    payload = message[type] || {}
    content_for(type, payload)
  end

  def content_for(type, payload)
    return media_content(payload) if MEDIA_TYPES.include?(type)

    builder = CONTENT_BUILDERS.fetch(type, :unsupported_content)
    builder == :history_media_copy ? history_media_copy : __send__(builder, payload)
  end

  def text_content(payload)
    payload['body']
  end

  def media_content(payload)
    payload['caption'].presence || payload['filename'].presence || history_media_copy
  end

  def location_content(payload)
    [payload['name'], payload['address']].compact_blank.join(', ')
  end

  def interactive_content(payload)
    payload.dig('button_reply', 'title') || payload.dig('list_reply', 'title')
  end

  def button_content(payload)
    payload['text']
  end

  def unsupported_content(_payload)
    I18n.t('conversations.messages.whatsapp.history_unsupported')
  end

  def history_media_copy
    I18n.t('conversations.messages.whatsapp.history_media')
  end
end
