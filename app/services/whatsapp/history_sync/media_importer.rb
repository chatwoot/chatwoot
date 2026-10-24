class Whatsapp::HistorySync::MediaImporter
  MEDIA_TYPES = %w[audio document image sticker video voice].freeze

  def initialize(sync)
    @sync = sync
    @channel = sync.channel
    @inbox = @channel.inbox
  end

  def perform(media_assets)
    imported = media_assets.count { |message| attach_media(message) }
    Rails.logger.info("[WHATSAPP HISTORY SYNC] Attached #{imported} historical media assets for sync #{sync.id}")
    imported
  end

  private

  attr_reader :sync, :channel, :inbox

  def attach_media(media_message)
    message = inbox.messages.find_by(source_id: media_message.fetch('id').to_s)
    raise_missing_message(media_message) unless message

    type = media_message['type'].to_s
    payload = media_message[type] || {}
    return false unless MEDIA_TYPES.include?(type) && payload['id'].present?
    return false if message.attachments.exists?

    create_attachment(message, payload, type)
    update_media_message(message, payload)
    true
  end

  def raise_missing_message(media_message)
    raise Whatsapp::HistorySync::Importer::MissingHistoricalMessageError,
          "Historical message #{media_message['id']} has not arrived yet"
  end

  def create_attachment(message, payload, type)
    file = download_attachment_file(payload)
    message.attachments.create!(
      account_id: message.account_id,
      file_type: file_content_type(type),
      file: {
        io: file,
        filename: payload['filename'].presence || file.original_filename,
        content_type: file.content_type
      }
    )
  end

  def update_media_message(message, payload)
    content = payload['caption'].presence || payload['filename'].presence
    attributes = message.additional_attributes.merge('history_media_imported' => true)
    updates = { additional_attributes: attributes, updated_at: Time.current }
    updates[:content] = updates[:processed_message_content] = content if content.present?
    message.update_columns(updates) # rubocop:disable Rails/SkipsModelValidations
  end

  def download_attachment_file(payload)
    response = HTTParty.get(channel.media_url(payload.fetch('id')), headers: channel.api_headers)
    channel.authorization_error! if response.unauthorized?
    raise "Historical media URL request failed: #{response.code}" unless response.success?

    Down.download(response.parsed_response.fetch('url'), headers: channel.api_headers)
  end

  def file_content_type(type)
    return :image if %w[image sticker].include?(type)
    return :audio if %w[audio voice].include?(type)
    return :video if type == 'video'

    :file
  end
end
