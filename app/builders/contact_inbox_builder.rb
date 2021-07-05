class ContactInboxBuilder
  pattr_initialize [:contact_id!, :inbox_id!, :source_id]

  def perform
    @contact = Contact.find(contact_id)
    @inbox = @contact.account.inboxes.find(inbox_id)
    return unless ['Channel::TwilioSms', 'Channel::Email', 'Channel::Api'].include? @inbox.channel_type

    source_id = @source_id || generate_source_id
    create_contact_inbox(source_id) if source_id.present?
  end

  private

  def generate_source_id
    return twilio_source_id if @inbox.channel_type == 'Channel::TwilioSms'
    return @contact.email if @inbox.channel_type == 'Channel::Email'
    return SecureRandom.uuid if @inbox.channel_type == 'Channel::Api'

    nil
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
