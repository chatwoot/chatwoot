# This Builder will create a contact inbox with specified attributes. If the contact inbox already exists, it will be returned.
# For Specific Channels like whatsapp, email etc . it smartly generated appropriate the source id when none is provided.

class ContactInboxBuilder
  pattr_initialize [:contact, :inbox, :source_id, { hmac_verified: false }]

  def perform
    @source_id ||= generate_source_id
    create_contact_inbox if source_id.present?
  end

  private

  def generate_source_id
    case @inbox.channel_type
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
      raise "Unsupported operation for this channel: #{@inbox.channel_type}"
    end
  end

  def email_source_id
    raise ActionController::ParameterMissing, 'contact email' unless @contact.email

    @contact.email
  end

  def phone_source_id
    raise ActionController::ParameterMissing, 'contact phone number' unless @contact.phone_number

    @contact.phone_number
  end

  def wa_source_id
    raise ActionController::ParameterMissing, 'contact phone number' unless @contact.phone_number

    # whatsapp doesn't want the + in e164 format
    @contact.phone_number.delete('+').to_s
  end

  def twilio_source_id
    raise ActionController::ParameterMissing, 'contact phone number' unless @contact.phone_number

    case @inbox.channel.medium
    when 'sms'
      @contact.phone_number
    when 'whatsapp'
      "whatsapp:#{@contact.phone_number}"
    end
  end

  def create_contact_inbox
    attrs = {
      contact_id: @contact.id,
      inbox_id: @inbox.id,
      source_id: @source_id
    }

    ::ContactInbox.where(attrs).first_or_create!(hmac_verified: hmac_verified || false)
  rescue ActiveRecord::RecordNotUnique
    Rails.logger.info("[ContactInboxBuilder] RecordNotUnique #{@source_id} #{@contact.id} #{@inbox.id}")
    update_old_contact_inbox
    retry
  end

  def update_old_contact_inbox
    # The race condition occurs when there’s a contact inbox with the
    # same source ID but linked to a different contact. This can happen
    # if the agent updates the contact’s email or phone number, or
    # if the contact is merged with another.
    #
    # We update the old contact inbox source_id to a random value to
    # avoid disrupting the current flow. However, the root cause of
    # this issue is a flaw in the contact inbox model design.
    # Contact inbox is essentially tracking a session and is not
    # needed for non-live chat channels.
    raise ActiveRecord::RecordNotUnique unless allowed_channels?

    contact_inbox = ::ContactInbox.find_by(inbox_id: @inbox.id, source_id: @source_id)
    return if contact_inbox.blank?

    contact_inbox.update!(source_id: new_source_id)
  end

  def new_source_id
    if @inbox.whatsapp? || @inbox.sms? || @inbox.twilio?
      "whatsapp:#{@source_id}#{rand(100)}"
    else
      "#{rand(10)}#{@source_id}"
    end
  end

  def allowed_channels?
    @inbox.email? || @inbox.sms? || @inbox.twilio? || @inbox.whatsapp?
  end
end
