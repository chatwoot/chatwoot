# This Builder will create a contact inbox with specified attributes. If the contact inbox already exists, it will be returned.
# For Specific Channels like whatsapp, email etc . it smartly generated appropriate the source id when none is provided.

class ContactInboxBuilder
  pattr_initialize [:contact, :inbox, :source_id, { hmac_verified: false, validate_whatsapp_phone: false }]

  def perform
    normalize_phone_for_whatsapp! if validate_whatsapp_phone && whatsapp_session_inbox? && number_check.answerable?
    @source_id ||= generate_source_id
    return if source_id.blank?

    contact_inbox = create_contact_inbox
    record_whatsapp_presence(contact_inbox)
    contact_inbox
  end

  private

  # Providers that address a contact by the exact number registered on WhatsApp, rather
  # than by the account's canonical phone. Z-API is frozen legacy and keeps its current
  # behavior of not resolving the number.
  def whatsapp_session_inbox?
    return false unless @inbox.channel_type == 'Channel::Whatsapp'

    @inbox.channel.session_provider? || @inbox.channel.provider == 'baileys'
  end

  def number_check
    @number_check ||= Whatsapp::NumberCheck.new(inbox: @inbox)
  end

  # Resolve the canonical number and align the contact (and source_id) with what the paired
  # session expects. Provider lookup errors are swallowed; write/merge errors must surface so
  # the caller sees inconsistent state.
  def normalize_phone_for_whatsapp!
    return if @contact.phone_number.blank?

    old_source_id_candidate = @contact.phone_number.delete('+')

    @looked_up_phone = @contact.phone_number
    @flags_before = whatsapp_flags(@contact)
    @asked_at = Time.current
    # A web request waits on this, and rack-timeout cuts it from outside: the lookup gives up
    # first, and the conversation is created with the typed phone.
    @whatsapp_answer = number_check.lookup(@looked_up_phone, deadline: :request)
    canonical_phone = @whatsapp_answer&.phone
    return if canonical_phone.blank? || canonical_phone == @contact.phone_number

    @contact = number_check.align_contact(@contact, canonical_phone)
    @looked_up_phone = canonical_phone
    # A merge hands the answer to another contact, whose flags this request has not read yet.
    # Read now, after the lookup, they are what the alignment applies the answer to.
    @flags_before = whatsapp_flags(@contact)

    @source_id = canonical_phone.delete('+') if @source_id == old_source_id_candidate
  end

  def whatsapp_flags(contact)
    contact.contact_inboxes.where(inbox: @inbox).pluck(:id, :whatsapp_missing_checked_at).to_h
  end

  # Every conversation started here asks afresh, so the answer replaces whatever an earlier
  # one left on the contact inbox: the conversation warns while it says "no WhatsApp", and a
  # number that registered since stops warning. No answer changes nothing, and either answer
  # is dropped if the phone or the flag moved while the provider was answering. A "yes" that
  # aligned the contact is about the canonical phone it now holds.
  def record_whatsapp_presence(contact_inbox)
    return if @whatsapp_answer.nil?

    return clear_answered_threads(contact_inbox) if @whatsapp_answer.exists

    contact_inbox.mark_whatsapp_missing_for!(@looked_up_phone, flag_before: @flags_before[contact_inbox.id], asked_at: @asked_at)
  end

  # A "yes" is about the phone, so every thread of the contact in this inbox stops warning,
  # not only the one this conversation uses.
  def clear_answered_threads(contact_inbox)
    ContactInbox.where(id: @flags_before.keys | [contact_inbox.id]).find_each do |thread|
      thread.clear_whatsapp_missing_for!(@looked_up_phone, flag_before: @flags_before[thread.id])
    end
  end

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

ContactInboxBuilder.prepend_mod_with('ContactInboxBuilder')
