class Voice::InboundCallBuilder < Voice::BaseCallBuilder
  def initialize(account:, inbox:, from_number:, call_sid:, to_number: nil)
    super(
      account: account,
      inbox: inbox,
      call_sid: call_sid,
      direction: 'inbound',
      from_number: from_number,
      to_number: to_number || inbox.channel&.phone_number,
      user: nil,
      contact: nil
    )
  end

  private

  def create_conversation!
    contact_record = find_or_create_contact
    contact_inbox = find_or_create_contact_inbox(contact_record)
    attrs = {
      'call_direction' => 'inbound',
      'call_type' => 'inbound',
      'call_status' => 'ringing',
      'meta' => { 'initiated_at' => Time.current.to_i }
    }

    account.conversations.create!(
      contact_inbox_id: contact_inbox.id,
      inbox_id: inbox.id,
      contact_id: contact_record.id,
      status: :open,
      additional_attributes: attrs
    ).tap do |conv|
      conv.reload
      @contact = contact_record
    end
  end

  def conversation_metadata_overrides
    {}
  end

  def find_or_create_contact
    account.contacts.find_or_create_by!(phone_number: from_number_for_message) do |c|
      c.name = from_number_for_message
    end
  end

  def find_or_create_contact_inbox(contact_record)
    ContactInbox.find_or_create_by!(
      contact_id: contact_record.id,
      inbox_id: inbox.id,
      source_id: from_number_for_message
    )
  end

  def log_success!
    Rails.logger.info(
      "VOICE_INBOUND_BUILDER account=#{account.id} inbox=#{inbox.id} conv=#{conversation.display_id} from=#{from_number_for_message} call_sid=#{call_sid}"
    )
  end
end
