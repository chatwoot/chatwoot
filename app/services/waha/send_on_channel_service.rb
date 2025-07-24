class Waha::SendOnChannelService
  pattr_initialize [:message!]

  def perform
    validate_target_channel
    return unless outgoing_message?
    return if invalid_message?

    perform_reply
  end

  private

  delegate :conversation, to: :message
  delegate :contact, :contact_inbox, :inbox, to: :conversation
  delegate :channel, to: :inbox

  def channel_class
    Channel::WhatsappUnofficial
  end

  def perform_reply
    params = { to: contact_inbox.source_id }

    if message.content_type == 'location' && message.content_attributes['data']
      location_data = message.content_attributes['data']
      params[:location] = {
        latitude: location_data['latitude'],
        longitude: location_data['longitude'],
        name: location_data['name'],
        address: location_data['address']
      }
    else
      params[:message] = message.content
      image_attachment = message.attachments.find { |a| a.file_type == 'image' }
      if image_attachment.present?
        begin
          file = Tempfile.new(image_attachment.file.filename)
          file.binmode
          file.write(image_attachment.file.download)
          file.rewind
          params[:image_path] = file.path
        rescue StandardError => e
          Rails.logger.error "Failed to process attachment for WAHA: #{e.message}"
        end
      end
    end

    # Panggil method send_message di channel dengan parameter yang sudah disiapkan
    response = channel.send_message(params)

    # Update message dengan source_id jika berhasil
    if response && response.dig('data', 'message_id').present?
      message.update!(source_id: response.dig('data', 'message_id'))
    end
  ensure
    file&.close
    file&.unlink
  end

  def outgoing_message_originated_from_channel?
    message.source_id.present?
  end

  def outgoing_message?
    message.outgoing? || message.template?
  end

  def invalid_message?
    message.private? || outgoing_message_originated_from_channel?
  end

  def validate_target_channel
    raise 'Invalid channel service was called' if inbox.channel.class != channel_class
  end
end