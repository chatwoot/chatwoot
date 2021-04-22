class Contacts::ContactableInboxesService
  pattr_initialize [:contact!]

  def get
    account = contact.account
    account.inboxes.map { |inbox| get_contactable_inbox(inbox) }.compact
  end

  private

  def get_contactable_inbox(inbox)
    return twilio_contactable_inbox(inbox) if inbox.channel_type == 'Channel::TwilioSms'
    return email_contactable_inbox(inbox) if inbox.channel_type == 'Channel::Email'
    return api_contactable_inbox(inbox) if inbox.channel_type == 'Channel::Api'
    return website_contactable_inbox(inbox) if inbox.channel_type == 'Channel::WebWidget'

    nil
  end

  def website_contactable_inbox(inbox)
    latest_contact_inbox = inbox.contact_inboxes.where(contact: @contact).last
    return unless latest_contact_inbox
    # FIXME : change this when multiple conversations comes in
    return if latest_contact_inbox.conversations.present?

    { source_id: latest_contact_inbox.source_id, inbox: inbox }
  end

  def api_contactable_inbox(inbox)
    latest_contact_inbox = inbox.contact_inboxes.where(contact: @contact).last
    source_id = latest_contact_inbox&.source_id || SecureRandom.uuid

    { source_id: source_id, inbox: inbox }
  end

  def email_contactable_inbox(inbox)
    return unless @contact.email

    { source_id: @contact.email, inbox: inbox }
  end

  def twilio_contactable_inbox(inbox)
    return if @contact.phone_number.blank?

    case inbox.channel.medium
    when 'sms'
      { source_id: @contact.phone_number, inbox: inbox }
    when 'whatsapp'
      { source_id: "whatsapp:#{@contact.phone_number}", inbox: inbox }
    end
  end
end
