class ContactInboxBuilder
  pattr_initialize [:contact_id!, :inbox_id!, :source_id]

  def perform
    @contact = Contact.find(contact_id)
    @inbox = @contact.account.inboxes.find(inbox_id)
    return unless ['Channel::TwilioSms', 'Channel::Sms', 'Channel::Email', 'Channel::Api', 'Channel::Whatsapp'].include? @inbox.channel_type

    source_id = @source_id || generate_source_id
    create_contact_inbox(source_id) if source_id.present?
  end

  private

  def generate_source_id
    case @inbox.channel_type
    when 'Channel::TwilioSms'
      twilio_source_id
    when 'Channel::Whatsapp'
      wa_source_id
    when 'Channel::Email'
      @contact.email
    when 'Channel::Sms'
      @contact.phone_number
    when 'Channel::Api'
      SecureRandom.uuid
    end
  end

  def wa_source_id
    return unless @contact.phone_number

    # whatsapp doesn't want the + in e164 format
    "#{@contact.phone_number}.delete('+')"
  end

  def twilio_source_id
    return unless @contact.phone_number

    case @inbox.channel.medium
    when 'sms'
      @contact.phone_number
    when 'whatsapp'
      "whatsapp:#{@contact.phone_number}"
    end
  end

  def create_contact_inbox(source_id)
    ::ContactInbox.find_or_create_by!(
      contact_id: @contact.id,
      inbox_id: @inbox.id,
      source_id: source_id
    )
  end
end
