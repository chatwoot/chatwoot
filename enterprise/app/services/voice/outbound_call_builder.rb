class Voice::OutboundCallBuilder
  pattr_initialize [:account!, :inbox!, :user!, :contact!, :call_sid!, :to_number!]

  attr_reader :conversation

  def perform
    contact_inbox = find_or_create_contact_inbox!
    @conversation = create_conversation!(contact_inbox)
    set_identifier_and_conference_sid!
    create_call_message!

    Rails.logger.info(
      "VOICE_OUTBOUND_BUILDER account=#{account.id} inbox=#{inbox.id} conv=#{@conversation.display_id} to=#{to_number} call_sid=#{call_sid}"
    )
    @conversation
  end

  private

  def find_or_create_contact_inbox!
    ContactInbox.find_or_create_by!(
      contact_id: contact.id,
      inbox_id: inbox.id
    ) { |ci| ci.source_id = contact.phone_number }
  end

  def create_conversation!(contact_inbox)
    account.conversations.create!(
      contact_inbox_id: contact_inbox.id,
      inbox_id: inbox.id,
      contact_id: contact.id,
      status: :open,
      additional_attributes: outbound_attributes
    ).tap(&:reload)
  end

  def outbound_attributes
    {
      'call_direction' => 'outbound',
      'call_type' => 'outbound',
      'requires_agent_join' => true,
      'agent_id' => user.id,
      'meta' => { 'initiated_at' => Time.now.to_i },
      'call_status' => 'ringing'
    }
  end

  def set_identifier_and_conference_sid!
    @conversation.update!(identifier: call_sid)
    conf = "conf_account_#{account.id}_conv_#{@conversation.display_id}"
    attrs = @conversation.additional_attributes.merge('conference_sid' => conf)
    @conversation.update!(additional_attributes: attrs)
  end

  def create_call_message!
    content_attrs = {
      data: {
        call_sid: call_sid,
        status: 'ringing',
        conversation_id: @conversation.display_id,
        call_direction: 'outbound',
        from_number: inbox.channel&.phone_number || '',
        to_number: to_number,
        meta: {
          created_at: Time.current.to_i,
          ringing_at: Time.current.to_i
        }
      }
    }

    @conversation.messages.create!(
      account_id: account.id,
      inbox_id: inbox.id,
      message_type: :outgoing,
      sender: user,
      content: 'Voice Call',
      content_type: 'voice_call',
      content_attributes: content_attrs
    )
  end
end

