class AppleMessagesForBusiness::SendTimePickerService < AppleMessagesForBusiness::SendMessageService
  def perform
    # Save images before sending
    save_images_to_storage

    # Call parent perform
    super
  end

  # Override parent's build_interactive_data to include images
  def build_interactive_data
    base_data = {
      bid: 'com.apple.messages.MSMessageExtensionBalloonPlugin:0000000000:com.apple.icloud.apps.messages.business.extension',
      data: {
        version: '1.0',
        requestIdentifier: SecureRandom.uuid,
        event: build_time_picker_data
      },
      useLiveLayout: true,
      receivedMessage: build_received_message,
      replyMessage: build_reply_message
    }

    # Fetch and include images
    images = build_images_array
    base_data[:data][:images] = images if images.present?

    Rails.logger.info "[AMB TimePicker] build_interactive_data - Images included: #{images&.length || 0}"

    base_data
  end

  private

  def message_payload
    {
      sourceId: source_id,
      destinationId: destination_id,
      v: 1,
      type: 'interactive',
      interactiveData: {
        bid: channel.imessage_extension_bid,
        data: {
          requestIdentifier: SecureRandom.uuid,
          mspVersion: '1.0',
          event: build_event_data,
          images: build_images_array
        },
        receivedMessage: build_received_message,
        replyMessage: build_reply_message
      }
    }
  end

  def save_images_to_storage
    images = content_attributes['images'] || []
    Rails.logger.info "[AMB TimePicker] save_images_to_storage called with #{images.length} images"
    return if images.empty?

    images.each do |image_data|
      Rails.logger.info "[AMB TimePicker] Processing image: #{image_data['identifier']}, has data: #{image_data['data'].present?}"
      next if image_data['identifier'].blank? || image_data['data'].blank?

      # Check if image already exists
      existing_image = AppleListPickerImage.find_by_identifier(
        message.inbox_id,
        image_data['identifier']
      )

      Rails.logger.info "[AMB TimePicker] Existing image found: #{existing_image.present?}, has attachment: #{existing_image&.image&.attached?}"

      # Skip if already saved
      next if existing_image&.image&.attached?

      # Create or update the image record
      picker_image = existing_image || AppleListPickerImage.new(
        account_id: message.account_id,
        inbox_id: message.inbox_id,
        identifier: image_data['identifier']
      )

      picker_image.description = image_data['description']
      picker_image.original_name = image_data['originalName'] || image_data['identifier']

      # Decode base64 and attach to ActiveStorage
      begin
        decoded_data = Base64.strict_decode64(image_data['data'])

        # Determine filename and content type
        filename = picker_image.original_name || "#{image_data['identifier']}.jpg"
        content_type = determine_content_type(decoded_data, filename)

        # Attach to ActiveStorage
        picker_image.image.attach(
          io: StringIO.new(decoded_data),
          filename: filename,
          content_type: content_type
        )

        picker_image.save!
        Rails.logger.info "[AMB TimePicker] Successfully saved image to ActiveStorage: #{image_data['identifier']}"
      rescue StandardError => e
        Rails.logger.error "[AMB TimePicker] Failed to save image #{image_data['identifier']}: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        # Continue processing other images
      end
    end
  end

  def determine_content_type(data, filename)
    # Try to detect from data
    return 'image/png' if data[0..3] == "\x89PNG"
    return 'image/jpeg' if data[0..1] == "\xFF\xD8"
    return 'image/gif' if data[0..2] == 'GIF'
    return 'image/webp' if data[8..11] == 'WEBP'

    # Fallback to filename extension
    ext = File.extname(filename).downcase
    case ext
    when '.png' then 'image/png'
    when '.jpg', '.jpeg' then 'image/jpeg'
    when '.gif' then 'image/gif'
    when '.webp' then 'image/webp'
    else 'image/jpeg' # default
    end
  end

  def build_time_picker_data
    event_data = content_attributes['event'] || {}

    # Handle both camelCase and snake_case for imageIdentifier (frontend sends camelCase)
    image_identifier = event_data['image_identifier'] || event_data['imageIdentifier']

    {
      identifier: event_data['identifier'] || SecureRandom.uuid,
      title: event_data['title'] || 'Select a time',
      imageIdentifier: image_identifier,
      location: build_location_data(event_data['location']),
      timeslots: build_timeslots(event_data['timeslots'] || default_timeslots),
      timezoneOffset: event_data['timezone_offset']
    }
  end

  def build_location_data(location)
    return nil unless location

    {
      latitude: location['latitude']&.to_f,
      longitude: location['longitude']&.to_f,
      radius: location['radius']&.to_f || 100.0,
      title: location['title']
    }
  end

  def build_timeslots(timeslots)
    timeslots.map do |slot|
      # Handle both camelCase (from frontend) and snake_case
      start_time = slot['startTime'] || slot['start_time']

      {
        identifier: slot['identifier'] || SecureRandom.uuid,
        startTime: format_iso8601_time(start_time),
        duration: slot['duration']&.to_i || 3600 # Default 1 hour in seconds
      }
    end
  end

  def format_iso8601_time(time_input)
    return nil unless time_input

    # Parse various time formats and convert to ISO-8601 format required by Apple
    # Format: 2017-05-26T08:27+0000 (no seconds, no Z notation)
    time = case time_input
           when String
             Time.parse(time_input)
           when Integer
             Time.at(time_input)
           when Time
             time_input
           else
             Time.current
           end

    time.utc.strftime('%Y-%m-%dT%H:%M+0000')
  rescue ArgumentError
    # Fallback to current time if parsing fails
    Time.current.utc.strftime('%Y-%m-%dT%H:%M+0000')
  end

  def build_images_array
    Rails.logger.info '[AMB TimePicker] build_images_array called'
    Rails.logger.info "[AMB TimePicker] content_attributes keys: #{content_attributes.keys.inspect}"
    Rails.logger.info "[AMB TimePicker] received_image_identifier: #{content_attributes['received_image_identifier'].inspect}"
    Rails.logger.info "[AMB TimePicker] receivedImageIdentifier: #{content_attributes['receivedImageIdentifier'].inspect}"

    images_data = content_attributes['images'] || []
    all_images = []

    # First, include any images provided directly with base64 data
    if images_data.any? && images_data.first['data'].present?
      Rails.logger.info "[AMB TimePicker] Using #{images_data.length} images from content_attributes"
      all_images = images_data.map do |image|
        {
          identifier: image['identifier'],
          data: image['data'], # Base64 encoded image data
          description: image['description']
        }
      end
    end

    # Collect all image identifiers referenced in event, received_message, and reply_message
    image_identifiers = []
    event_data = content_attributes['event'] || {}
    image_identifiers << (event_data['image_identifier'] || event_data['imageIdentifier'])
    image_identifiers << (content_attributes['received_image_identifier'] || content_attributes['receivedImageIdentifier'])
    image_identifiers << (content_attributes['reply_image_identifier'] || content_attributes['replyImageIdentifier'])
    image_identifiers.compact!
    image_identifiers.uniq!

    Rails.logger.info "[AMB TimePicker] Collected image identifiers: #{image_identifiers.inspect}"

    # Find which identifiers are NOT already in all_images (need to be fetched from database)
    existing_identifiers = all_images.map { |img| img[:identifier] }
    missing_identifiers = image_identifiers - existing_identifiers

    # Fetch missing images from database
    if missing_identifiers.any?
      Rails.logger.info "[AMB TimePicker] Fetching #{missing_identifiers.length} images from database: #{missing_identifiers.inspect}"

      fetched_images = AppleListPickerImage.where(
        inbox_id: message.inbox_id,
        identifier: missing_identifiers
      ).map do |picker_image|
        next unless picker_image.image.attached?

        Rails.logger.info "[AMB TimePicker] Found image: #{picker_image.identifier}"
        {
          identifier: picker_image.identifier,
          data: Base64.strict_encode64(picker_image.image.download),
          description: picker_image.description
        }
      end.compact

      all_images.concat(fetched_images)
      Rails.logger.info "[AMB TimePicker] Total images after database fetch: #{all_images.length}"
    end

    all_images
  end

  def build_received_message
    # Handle both camelCase and snake_case for imageIdentifier (frontend sends camelCase)
    received_image_id = content_attributes['received_image_identifier'] || content_attributes['receivedImageIdentifier']

    {
      title: content_attributes['received_title'] || 'Select a time',
      subtitle: content_attributes['received_subtitle'],
      imageIdentifier: received_image_id,
      style: content_attributes['received_style'] || 'large'
    }
  end

  def build_reply_message
    # Handle both camelCase and snake_case for imageIdentifier (frontend sends camelCase)
    reply_image_id = content_attributes['reply_image_identifier'] || content_attributes['replyImageIdentifier']

    # If reply image is not specified, reuse the received image identifier
    # This follows Apple MSP best practice: reply message should show the same image as received message
    if reply_image_id.blank?
      received_image_id = content_attributes['received_image_identifier'] || content_attributes['receivedImageIdentifier']
      reply_image_id = received_image_id
    end

    {
      title: content_attributes['reply_title'] || 'Selected: ${event.title}',
      subtitle: content_attributes['reply_subtitle'],
      imageIdentifier: reply_image_id,
      style: content_attributes['reply_style'] || 'large'
    }
  end

  def default_timeslots
    # Provide some default time slots for the next few hours
    base_time = Time.current.beginning_of_hour + 1.hour

    3.times.map do |i|
      slot_time = base_time + (i * 2).hours
      {
        'identifier' => SecureRandom.uuid,
        'start_time' => slot_time.iso8601,
        'duration' => 3600
      }
    end
  end

  def content_attributes
    @content_attributes ||= message.content_attributes || {}
  end
end
