class AppleMessagesForBusiness::SendMessageService
  AMB_SERVER = 'https://mspgw.push.apple.com/v1'.freeze

  def initialize(channel:, destination_id:, message:)
    @channel = channel
    @destination_id = destination_id
    @message = message
  end

  def perform
    case @message.content_type
    when 'text'
      send_text_message
    when 'apple_list_picker'
      send_interactive_message
    when 'apple_time_picker'
      send_interactive_message
    when 'apple_quick_reply'
      send_interactive_message
    when 'apple_rich_link'
      send_rich_link_message
    else
      send_text_message # fallback
    end
  rescue StandardError => e
    Rails.logger.error "Apple Messages send failed: #{e.message}"
    { success: false, error: e.message }
  end

  private

  def send_text_message
    message_id = SecureRandom.uuid

    # All messages must be type "text" according to Apple MSP spec
    # The body field is required for type "text"
    has_text = @message.content.present?
    has_attachments = @message.attachments.present?

    return { success: false, error: 'Message has no content or attachments' } if !has_text && !has_attachments

    # Build message body with Unicode Object Replacement Characters for attachments
    body_text = @message.content || ''
    if has_attachments
      # Add one Unicode Object Replacement Character (\uFFFC) for each attachment
      attachment_placeholders = "\uFFFC" * @message.attachments.count
      body_text = has_text ? "#{body_text} #{attachment_placeholders}" : attachment_placeholders
    end

    payload = {
      id: message_id,
      type: 'text',
      sourceId: @channel.business_id,
      destinationId: @destination_id,
      v: 1,
      body: body_text,
      locale: 'en_US'
    }

    # Add attachments if present
    if has_attachments
      attachments_result = process_attachments
      return attachments_result unless attachments_result[:success]

      payload[:attachments] = attachments_result[:attachments]
    end

    response = send_to_apple_gateway(payload, message_id)

    if response.success?
      { success: true, message_id: message_id }
    else
      { success: false, error: "HTTP #{response.code}: #{response.body}" }
    end
  end

  def send_interactive_message
    message_id = SecureRandom.uuid

    payload = build_apple_msp_payload(message_id)

    response = send_to_apple_gateway(payload, message_id)

    if response.success?
      { success: true, message_id: message_id }
    else
      { success: false, error: "HTTP #{response.code}: #{response.body}" }
    end
  end

  # Build the correct Apple MSP interactive message format
  def build_apple_msp_payload(message_id)
    {
      v: 1,
      id: message_id,
      sourceId: source_id,
      destinationId: destination_id,
      type: 'interactive',
      interactiveData: build_interactive_data
    }
  end

  # Build the interactiveData structure according to Apple MSP spec
  def build_interactive_data
    base_data = {
      bid: 'com.apple.messages.MSMessageExtensionBalloonPlugin:0000000000:com.apple.icloud.apps.messages.business.extension',
      data: {
        version: '1.0',
        requestIdentifier: SecureRandom.uuid
      },
      useLiveLayout: true
    }

    # Add images array if present
    images = content_attributes['images']
    base_data[:data][:images] = images if images.present?

    # Add the specific interactive content based on message type
    case @message.content_type
    when 'apple_quick_reply'
      base_data[:data]['quick-reply'] = build_quick_reply_data
    when 'apple_list_picker'
      base_data[:data][:listPicker] = build_list_picker_data
      base_data[:receivedMessage] = build_received_message
      base_data[:replyMessage] = build_reply_message
    when 'apple_time_picker'
      # Time picker should have event directly in data, not nested under timePicker
      base_data[:data][:event] = build_time_picker_data
      base_data[:receivedMessage] = build_received_message
      base_data[:replyMessage] = build_reply_message
    end

    base_data
  end

  # Override these methods in subclasses for specific message types
  def build_quick_reply_data
    {
      summaryText: content_attributes['summary_text'] || @message.content,
      items: content_attributes['items'] || []
    }
  end

  def build_list_picker_data
    sections = content_attributes['sections'] || []

    # Add missing order and style fields according to Apple MSP spec
    sections.each_with_index do |section, section_index|
      section['order'] = section_index unless section.key?('order')

      next unless section['items']

      section['items'].each_with_index do |item, item_index|
        item['order'] = item_index unless item.key?('order')
        item['style'] = 'icon' unless item.key?('style')
      end
    end

    {
      sections: sections
    }
  end

  def build_time_picker_data
    # Return event structure directly (not nested under timePicker)
    event_data = content_attributes['event'] || {}

    # Add timezone offset if present at top level (for backward compatibility)
    event_data['timezoneOffset'] = content_attributes['timezone_offset'] if content_attributes['timezone_offset'] && !event_data['timezoneOffset']

    # Add timeslots if present at top level (for backward compatibility)
    event_data['timeslots'] = content_attributes['timeslots'] if content_attributes['timeslots'] && !event_data['timeslots']

    # Fix timeslot format for Apple's requirements
    if event_data['timeslots'].present?
      has_timezone_in_times = event_data['timeslots'].any? { |slot| slot['startTime']&.include?('+') || slot['startTime']&.include?('Z') }

      event_data['timeslots'] = event_data['timeslots'].map do |slot|
        start_time = slot['startTime']

        # Convert local time to GMT if it contains timezone info
        if start_time&.include?('+') || start_time&.include?('Z')
          begin
            parsed_time = Time.parse(start_time)
            start_time = parsed_time.utc.strftime('%Y-%m-%dT%H:%M+0000')
          rescue StandardError
            # If parsing fails, keep original format
          end
        end

        {
          'identifier' => slot['identifier'],  # Apple expects identifier first
          'startTime' => start_time,
          'duration' => convert_duration_if_needed(slot['duration'])
        }
      end

      # Use Apple's "User timezone approach": If we converted times to GMT, remove timezoneOffset
      # This lets Apple display times in the user's local timezone automatically
      if has_timezone_in_times
        event_data.delete('timezoneOffset')
      end
    end

    event_data
  end

  private

  def convert_duration_if_needed(duration)
    # Apple working sample uses seconds (3600), but ensure consistency
    # If duration is less than 300, assume it's already in minutes and convert to seconds
    duration_int = duration.to_i
    duration_int < 300 ? (duration_int * 60) : duration_int
  end

  def build_received_message
    msg = {
      title: content_attributes['received_title'] || @message.content || 'Interactive Message',
      style: content_attributes['received_style'] || 'icon'
    }

    # Only add subtitle if explicitly provided
    msg[:subtitle] = content_attributes['received_subtitle'] if content_attributes['received_subtitle'].present?

    # Add imageIdentifier if provided
    msg[:imageIdentifier] = content_attributes['received_image_identifier'] if content_attributes['received_image_identifier'].present?

    msg
  end

  def build_reply_message
    msg = {
      title: content_attributes['reply_title'] || 'Selection Made',
      style: content_attributes['reply_style'] || 'icon'
    }

    # Only add subtitle if explicitly provided (Apple samples for time picker don't include subtitle)
    msg[:subtitle] = content_attributes['reply_subtitle'] if content_attributes['reply_subtitle'].present?

    # Add enriched replyMessage fields according to Apple MSP specification
    msg[:imageTitle] = content_attributes['reply_image_title'] if content_attributes['reply_image_title'].present?

    msg[:imageSubtitle] = content_attributes['reply_image_subtitle'] if content_attributes['reply_image_subtitle'].present?

    msg[:secondarySubtitle] = content_attributes['reply_secondary_subtitle'] if content_attributes['reply_secondary_subtitle'].present?

    msg[:tertiarySubtitle] = content_attributes['reply_tertiary_subtitle'] if content_attributes['reply_tertiary_subtitle'].present?

    # Add imageIdentifier if provided
    msg[:imageIdentifier] = content_attributes['reply_image_identifier'] if content_attributes['reply_image_identifier'].present?

    msg
  end

  # Legacy method for backward compatibility - now delegates to build_apple_msp_payload
  def message_payload
    build_apple_msp_payload(SecureRandom.uuid)
  end

  def source_id
    @channel.business_id
  end

  attr_reader :destination_id, :channel, :message

  def content_attributes
    @message.content_attributes || {}
  end

  def send_rich_link_message
    # Delegate to the specialized RichLinkService
    service = AppleMessagesForBusiness::SendRichLinkService.new(
      channel: @channel,
      destination_id: @destination_id,
      message: @message
    )

    service.perform
  end

  def process_attachments
    attachments = []

    @message.attachments.each do |attachment|
      if attachment.file.attached?
        result = upload_attachment(attachment)
        return { success: false, error: "Failed to upload attachment #{attachment.file.filename}" } if result.nil?

        attachments << result
      else
        # Handle external attachments
        attachments << {
          name: attachment.fallback_title,
          url: attachment.external_url,
          mimeType: attachment.file.content_type || 'application/octet-stream'
        }
      end
    end

    { success: true, attachments: attachments }
  end

  def upload_attachment(attachment)
    file_data = attachment.file.download
    encrypted_data, decryption_key = AppleMessagesForBusiness::AttachmentCipherService.encrypt(file_data)

    Rails.logger.info "Uploading attachment: #{attachment.file.filename} (#{file_data.size} bytes -> #{encrypted_data.size} bytes encrypted)"

    # Pre-upload to get upload URL
    upload_info = pre_upload_attachment(encrypted_data.size)

    # Upload encrypted data
    upload_response = upload_to_mmcs(upload_info[:upload_url], encrypted_data)

    attachment_data = {
      :name => attachment.file.filename.to_s,
      :mimeType => attachment.file.content_type,
      :size => file_data.size.to_s, # Use original file size, not encrypted size
      'signature-base64' => upload_response[:signature],
      :url => upload_info[:mmcs_url],
      :owner => upload_info[:mmcs_owner],
      :key => decryption_key
    }

    Rails.logger.info "Attachment upload successful: #{attachment_data}"
    attachment_data
  rescue StandardError => e
    Rails.logger.error "Attachment upload failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    nil
  end

  def pre_upload_attachment(size)
    headers = {
      'Authorization' => "Bearer #{@channel.generate_jwt_token}",
      'Source-Id' => @channel.business_id,
      'MMCS-Size' => size.to_s
    }

    Rails.logger.info "Pre-upload request: #{AMB_SERVER}/preUpload with size: #{size}"

    response = HTTParty.get(
      "#{AMB_SERVER}/preUpload",
      headers: headers,
      timeout: 30
    )

    Rails.logger.info "Pre-upload response: #{response.code} - #{response.body}"

    raise "Pre-upload failed: #{response.code} #{response.body}" unless response.success?

    parsed = response.parsed_response
    {
      upload_url: parsed['upload-url'],
      mmcs_url: parsed['mmcs-url'],
      mmcs_owner: parsed['mmcs-owner']
    }
  end

  def upload_to_mmcs(upload_url, encrypted_data)
    headers = {
      'Content-Length' => encrypted_data.size.to_s,
      'Content-Type' => 'application/octet-stream'
    }

    Rails.logger.info "MMCS upload to: #{upload_url} with size: #{encrypted_data.size}"

    response = HTTParty.post(
      upload_url,
      body: encrypted_data,
      headers: headers,
      timeout: 60
    )

    Rails.logger.info "MMCS upload response: #{response.code} - #{response.body}"

    raise "MMCS upload failed: #{response.code} #{response.body}" unless response.success?

    parsed = response.parsed_response
    signature = parsed.dig('singleFile', 'fileChecksum')

    if signature.nil?
      Rails.logger.error "No fileChecksum in MMCS response: #{parsed}"
      raise 'MMCS upload failed: No fileChecksum in response'
    end

    {
      signature: signature
    }
  end

  def send_to_apple_gateway(payload, message_id)
    headers = {
      'Content-Type' => 'application/json',
      'Authorization' => "Bearer #{@channel.generate_jwt_token}",
      'id' => message_id,
      'Source-Id' => @channel.business_id,
      'Destination-Id' => @destination_id
    }

    HTTParty.post(
      "#{AMB_SERVER}/message",
      body: payload.to_json,
      headers: headers,
      timeout: 30
    )
  end
end
