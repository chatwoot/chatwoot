module Voice
  class ConversationFinderService
    pattr_initialize [:account!, :phone_number, :inbox, :call_sid, :is_outbound]

    def perform
      # First try to find existing conversation by call_sid if available
      conversation = find_by_call_sid if call_sid.present?
      return conversation if conversation

      # Ensure we have a phone number for new conversation creation
      validate_and_normalize_phone_number

      # If not found, create a new conversation
      create_new_conversation
  end

  private

    def validate_and_normalize_phone_number
      # Simple validation to ensure we have something to work with
      raise 'Phone number cannot be blank' if phone_number.blank?

      # Normalize the phone number (strip any whitespace)
      @phone_number = phone_number.strip
    end

    def find_by_call_sid
      account.conversations.where("additional_attributes->>'call_sid' = ?", call_sid).first
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

      # Find or initialize the contact inbox
      contact_inbox = ContactInbox.find_or_initialize_by(
        contact_id: contact.id,
        inbox_id: inbox.id
      )

      # Set source_id if not set - needed for properly mapping the conversation
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

      # Need to reload conversation to get the display_id populated by the database
      conversation.reload

      # Add conference_sid to attributes
      conference_sid = generate_conference_sid(conversation)
      conversation.additional_attributes['conference_sid'] = conference_sid
      conversation.save!

      conversation
    end

    def initial_attributes
      attributes = {
        'call_initiated_at' => Time.now.to_i
      }

      # Add call_sid if available
      attributes['call_sid'] = call_sid if call_sid.present?

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

    def generate_conference_sid(conversation)
      "conf_account_#{account.id}_conv_#{conversation.display_id}"
    end
    public :find_by_call_sid
  end
end
