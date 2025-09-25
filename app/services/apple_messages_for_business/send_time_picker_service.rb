class AppleMessagesForBusiness::SendTimePickerService < AppleMessagesForBusiness::SendMessageService
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

  def build_event_data
    event_data = content_attributes['event'] || {}
    
    {
      identifier: event_data['identifier'] || SecureRandom.uuid,
      title: event_data['title'] || 'Select a time',
      imageIdentifier: event_data['image_identifier'],
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
      {
        identifier: slot['identifier'] || SecureRandom.uuid,
        startTime: format_iso8601_time(slot['start_time']),
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
    images = content_attributes['images'] || []
    images.map do |image|
      {
        identifier: image['identifier'],
        data: image['data'], # Base64 encoded image data
        description: image['description']
      }
    end
  end

  def build_received_message
    {
      title: content_attributes['received_title'] || 'Select a time',
      subtitle: content_attributes['received_subtitle'],
      imageIdentifier: content_attributes['received_image_identifier'],
      style: content_attributes['received_style'] || 'large'
    }
  end

  def build_reply_message
    {
      title: content_attributes['reply_title'] || 'Selected: ${event.title}',
      subtitle: content_attributes['reply_subtitle'],
      imageIdentifier: content_attributes['reply_image_identifier'],
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