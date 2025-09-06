class Voice::InboundCallBuilder
  pattr_initialize [:account!, :inbox!, :from_number!, :to_number, :call_sid!]

  attr_reader :conversation

  def perform
    contact = find_or_create_contact!
    contact_inbox = find_or_create_contact_inbox!(contact)
    @conversation = find_or_create_conversation!(contact, contact_inbox)
    create_call_message_if_needed!
    self
  end

  def twiml_response
    response = Twilio::TwiML::VoiceResponse.new
    response.say(message: 'Please wait while we connect you to an agent')
    response.to_s
  end

  private

  def find_or_create_conversation!(contact, contact_inbox)
    account.conversations.find_or_create_by!(
      account_id: account.id,
      inbox_id: inbox.id,
      identifier: call_sid
    ) do |conv|
      conv.contact_id = contact.id
      conv.contact_inbox_id = contact_inbox.id
      conv.additional_attributes = {
        'call_direction' => 'inbound',
        'call_status' => 'ringing'
      }
    end
  end

  def create_call_message!
    content_attrs = call_message_content_attributes

    @conversation.messages.create!(
      account_id: account.id,
      inbox_id: inbox.id,
      message_type: :incoming,
      sender: @conversation.contact,
      content: 'Voice Call',
      content_type: 'voice_call',
      content_attributes: content_attrs
    )
  end

  def create_call_message_if_needed!
    return if @conversation.messages.voice_calls.exists?

    create_call_message!
  end

  def call_message_content_attributes
    {
      data: {
        call_sid: call_sid,
        status: 'ringing',
        conversation_id: @conversation.display_id,
        call_direction: 'inbound',
        from_number: from_number,
        to_number: to_number,
        meta: {
          created_at: Time.current.to_i,
          ringing_at: Time.current.to_i
        }
      }
    }
  end

  def find_or_create_contact!
    account.contacts.find_by(phone_number: from_number) ||
      account.contacts.create!(phone_number: from_number, name: 'Unknown Caller')
  end

  def find_or_create_contact_inbox!(contact)
    ContactInbox.where(contact_id: contact.id, inbox_id: inbox.id, source_id: from_number).first_or_create!
  end
end
