class ContactInbox::SourceIdService
  pattr_initialize [:contact!, :channel_type!, { medium: nil }]

  def generate
    case channel_type
    when 'Channel::TwilioSms'
      twilio_source_id
    when 'Channel::Whatsapp'
      wa_source_id
    when 'Channel::Email'
      email_source_id
    when 'Channel::Sms'
      phone_source_id
    when 'Channel::Api', 'Channel::WebWidget'
      SecureRandom.uuid
    else
      raise ArgumentError, "Unsupported operation for this channel: #{channel_type}"
    end
  end

  private

  def email_source_id
    raise ArgumentError, 'contact email required' unless contact.email

    contact.email
  end

  def phone_source_id
    raise ArgumentError, 'contact phone number required' unless contact.phone_number

    contact.phone_number
  end

  def wa_source_id
    raise ArgumentError, 'contact phone number required' unless contact.phone_number

    # whatsapp doesn't want the + in e164 format
    contact.phone_number.delete('+').to_s
  end

  def twilio_source_id
    raise ArgumentError, 'contact phone number required' unless contact.phone_number
    raise ArgumentError, 'medium required for Twilio channel' if medium.blank?

    case medium
    when 'sms'
      contact.phone_number
    when 'whatsapp'
      "whatsapp:#{contact.phone_number}"
    else
      raise ArgumentError, "Unsupported Twilio medium: #{medium}"
    end
  end
end
