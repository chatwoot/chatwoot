class Voice::OutboundCallBuilder < Voice::BaseCallBuilder
  def initialize(account:, inbox:, user:, contact:, call_sid:, to_number: nil)
    super(
      account: account,
      inbox: inbox,
      call_sid: call_sid,
      direction: 'outbound',
      from_number: inbox.channel&.phone_number,
      to_number: to_number || contact.phone_number,
      user: user,
      contact: contact
    )
  end

  private

  def find_existing_conversation
    return if call_sid.blank?

    account.conversations.includes(:contact).find_by(identifier: call_sid)
  end

  def create_conversation!
    contact_inbox = find_or_create_contact_inbox(contact)
    attrs = {
      'call_direction' => 'outbound',
      'call_type' => 'outbound',
      'requires_agent_join' => true,
      'agent_id' => user.id,
      'call_status' => 'ringing',
      'meta' => { 'initiated_at' => Time.current.to_i }
    }

    account.conversations.create!(
      contact_inbox_id: contact_inbox.id,
      inbox_id: inbox.id,
      contact_id: contact.id,
      status: :open,
      additional_attributes: attrs
    ).tap(&:reload)
  end

  def find_or_create_contact_inbox(contact_record)
    ContactInbox.find_or_create_by!(
      contact_id: contact_record.id,
      inbox_id: inbox.id
    ) do |ci|
      ci.source_id = contact_record.phone_number
    end
  end

  def conversation_metadata_overrides
    {
      'requires_agent_join' => true,
      'agent_id' => user.id
    }
  end

  def message_sender
    user
  end

  def log_success!
    Rails.logger.info(
      "VOICE_OUTBOUND_BUILDER account=#{account.id} inbox=#{inbox.id} conv=#{conversation.display_id} to=#{to_number_for_message} call_sid=#{call_sid}"
    )
  end
end
