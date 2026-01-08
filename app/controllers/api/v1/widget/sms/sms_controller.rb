class Api::V1::Widget::Sms::SmsController < Api::V1::Widget::BaseController
  # Skip set_contact since we don't need it for SMS sending
  skip_before_action :set_contact, only: [:send_sms]

  def send_sms
    phone_number = permitted_params[:phone_number]
    message_content = permitted_params[:message]

    # Check if web_widget is set (from BaseController)
    unless @web_widget
      return render json: {
        error: 'Web widget not found. Invalid website_token.'
      }, status: :not_found
    end

    # Find SMS inbox in the same account
    sms_inbox = find_sms_inbox

    unless sms_inbox
      return render json: {
        error: 'No SMS inbox found. Please configure an SMS inbox in your account settings.'
      }, status: :not_found
    end

    # Create or find contact
    contact = find_or_create_contact(phone_number)

    # Create conversation if needed
    conversation = find_or_create_conversation(contact, sms_inbox)

    # Send SMS message
    begin
      send_sms_message(sms_inbox, phone_number, message_content, conversation)
      render json: { success: true, message: 'SMS sent successfully' }
    rescue StandardError => e
      render json: { error: "Failed to send SMS: #{e.message}" }, status: :internal_server_error
    end
  end

  private

  def permitted_params
    params.permit(:website_token, :phone_number, :message)
  end

  def find_sms_inbox
    # Try to find SMS inbox (Channel::Sms or Channel::TwilioSms)
    account = @web_widget.inbox.account

    # Try Channel::Sms first - use channel_type directly
    sms_inbox = account.inboxes.find_by(channel_type: 'Channel::Sms')
    return sms_inbox if sms_inbox

    # If not found, try Twilio SMS
    # Find all TwilioSms inboxes and filter by medium='sms'
    twilio_inboxes = account.inboxes.where(channel_type: 'Channel::TwilioSms').to_a
    twilio_inboxes.find do |inbox|
      channel = inbox.channel
      channel&.respond_to?(:medium) && channel.medium == 'sms'
    end
  end

  def find_or_create_contact(phone_number)
    account = @web_widget.inbox.account

    # Normalize phone number: remove spaces, dashes, parentheses, etc.
    normalized_phone = normalize_phone_number(phone_number)

    # Validate and parse phone number using TelephoneNumber gem
    parsed_phone = TelephoneNumber.parse(normalized_phone)

    unless parsed_phone&.valid?
      raise ArgumentError,
            'Invalid phone number format. Please enter a valid phone number with country code (e.g., +1234567890 for US, +919876543210 for India).'
    end

    # Get E.164 format phone number
    e164_phone = parsed_phone.e164_number

    # Try to find existing contact by phone number
    # Search for both E.164 format and normalized format to catch any variations
    contact = account.contacts.find_by(phone_number: e164_phone)

    # Also try to find by normalized phone (without E.164 conversion)
    contact = account.contacts.find_by(phone_number: normalized_phone) if !contact && normalized_phone != e164_phone

    # If still not found, try finding by phone number variations
    # This handles cases where phone numbers might be stored in slightly different formats
    unless contact
      search_phone = e164_phone.gsub(/^\+/, '').gsub(/^0+/, '')

      # Use a more efficient approach: fetch a limited set and compare in memory
      # This is still better than find_each on all contacts
      potential_contacts = account.contacts
                                  .where.not(phone_number: [nil, ''])
                                  .where('phone_number LIKE ? OR phone_number LIKE ?', "%#{search_phone}%", "#{search_phone}%")
                                  .limit(50)
                                  .to_a

      contact = potential_contacts.find do |c|
        existing_phone = c.phone_number&.gsub(/^\+/, '')&.gsub(/^0+/, '')
        existing_phone == search_phone
      end
    end

    # If not found, create new contact
    if contact
      # Update contact phone number to E.164 format if it's different
      contact.update!(phone_number: e164_phone) if contact.phone_number != e164_phone
    else
      contact = account.contacts.create!(
        phone_number: e164_phone,
        name: e164_phone # Default name to phone number
      )
    end

    contact
  end

  def normalize_phone_number(phone_number)
    return phone_number if phone_number.blank?

    # Remove all non-digit characters except the leading +
    # This handles spaces, dashes, parentheses, etc.
    normalized = phone_number.strip.gsub(/[^\d+]/, '')

    # Ensure it starts with +, if not add it
    normalized = "+#{normalized}" unless normalized.start_with?('+')

    normalized
  end

  def find_or_create_conversation(contact, sms_inbox)
    # First, try to find existing contact_inbox for this contact and inbox
    existing_contact_inbox = sms_inbox.contact_inboxes.find_by(contact_id: contact.id)

    contact_inbox = if existing_contact_inbox
                      existing_contact_inbox
                    else
                      # Use ContactInboxBuilder to create contact_inbox properly
                      ContactInboxBuilder.new(
                        contact: contact,
                        inbox: sms_inbox,
                        source_id: contact.phone_number
                      ).perform
                    end

    # Find existing conversation based on inbox's lock_to_single_conversation setting
    if sms_inbox.lock_to_single_conversation?
      # If locked to single conversation, always use the last conversation (and reopen if resolved)
      conversation = contact_inbox.conversations.order(created_at: :desc).first
      conversation.update!(status: :open) if conversation && conversation.resolved?
    else
      # If not locked, only use non-resolved conversations
      conversation = contact_inbox.conversations
                                  .where.not(status: :resolved)
                                  .order(created_at: :desc)
                                  .first
    end

    unless conversation
      conversation = Conversation.create!(
        account_id: sms_inbox.account_id,
        inbox_id: sms_inbox.id,
        contact_id: contact.id,
        contact_inbox_id: contact_inbox.id,
        status: :open
      )
      # Reload to ensure display_id and other computed attributes are persisted
      conversation.reload
    end

    conversation
  end

  def send_sms_message(sms_inbox, _phone_number, message_content, conversation)
    contact = conversation.contact

    # Create incoming message from the contact (as if they sent it to us)
    # Use create! directly to ensure all callbacks are triggered properly
    conversation.messages.create!(
      account_id: conversation.account_id,
      inbox_id: sms_inbox.id,
      content: message_content,
      message_type: :incoming,
      sender: contact
    )

    # NOTE: We do NOT send SMS here because this is an incoming message (from the user).
    # Only outgoing messages (agent replies) should be sent via Twilio.
    # Outgoing messages are automatically sent via SendReplyJob -> Twilio::SendOnTwilioService
  end
end
