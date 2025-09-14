module Voice
  class ConversationFinderService
    pattr_initialize [:account!, :phone_number, :inbox, :call_sid, :is_outbound]

  def perform
    # For outbound calls, always create a fresh conversation
    if is_outbound
      conv = create_new_conversation
      Rails.logger.info(
        "VOICE_CONV_FINDER_CREATED_OUTBOUND account=#{account.id} conv=#{conv.display_id} phone=#{phone_number} inbox=#{inbox.id}"
      )
      return conv
    end

    # For inbound: try to find existing conversation by call_sid if available
      conversation = find_by_call_sid if call_sid.present?
      if conversation
        Rails.logger.info(
          "VOICE_CONV_FINDER_FOUND_BY_SID account=#{account.id} conv=#{conversation.display_id} call_sid=#{call_sid}"
        )
        return conversation
      end

      # Ensure we have a phone number for new conversation creation
      validate_and_normalize_phone_number

      # If not found, create a new conversation
      conv = create_new_conversation
      Rails.logger.info(
        "VOICE_CONV_FINDER_CREATED account=#{account.id} conv=#{conv.display_id} phone=#{phone_number} inbox=#{inbox.id}"
      )
      conv
  end

  private

    def validate_and_normalize_phone_number
      # Simple validation to ensure we have something to work with
      raise 'Phone number cannot be blank' if phone_number.blank?

      # Normalize the phone number (strip any whitespace)
      @phone_number = phone_number.strip
    end

    def find_by_call_sid
      account.conversations.find_by(identifier: call_sid)
    end

    def find_or_create_contact
      # Always find or create a contact based on the phone number
      account.contacts.find_or_create_by!(phone_number: phone_number) do |c|
        c.name = phone_number
      end
    end

    def create_new_conversation
      # First ensure we have a contact
      contact = find_or_create_contact

      # Reuse existing contact_inbox (do not create new per outbound).
      # We still create a brand new Conversation below for every outbound call.
      contact_inbox = ContactInbox.find_or_initialize_by(
        contact_id: contact.id,
        inbox_id: inbox.id
      )
      contact_inbox.source_id ||= phone_number
      contact_inbox.save!

      # Create the conversation
      conversation = account.conversations.create!(
        contact_inbox_id: contact_inbox.id,
        inbox_id: inbox.id,
        contact_id: contact.id, # Explicitly set the contact_id to avoid any validation issues
        status: :open,
        additional_attributes: initial_attributes
      )

      # Ensure identifier set when call_sid available
      if call_sid.present?
        conversation.update!(identifier: call_sid)
      end

      # Need to reload conversation to get the display_id populated by the database
      conversation.reload

      conversation
    end

    def initial_attributes
      attributes = {
        'call_initiated_at' => Time.now.to_i
      }

      

      # Set call direction based on is_outbound flag
      if is_outbound
        attributes['call_direction'] = 'outbound'
        attributes['call_type'] = 'outbound'

        # For outbound calls, set the requires_agent_join flag
        # This is used by the CallStatusManager to identify outbound calls
        attributes['requires_agent_join'] = true
      else
        attributes['call_direction'] = 'inbound'
        attributes['call_type'] = 'inbound'
      end

      # Add metadata for tracking important timestamps
      attributes['meta'] = {
        'initiated_at' => Time.now.to_i
      }

      attributes
    end

    public :find_by_call_sid
  end
end
