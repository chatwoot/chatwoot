class Voice::InboundCallBuilder
  attr_reader :account, :inbox, :from_number, :call_sid

  def self.perform!(account:, inbox:, from_number:, call_sid:)
    new(account: account, inbox: inbox, from_number: from_number, call_sid: call_sid).perform!
  end

  def initialize(account:, inbox:, from_number:, call_sid:)
    @account = account
    @inbox = inbox
    @from_number = from_number
    @call_sid = call_sid
  end

  def perform!
    timestamp = current_timestamp

    ActiveRecord::Base.transaction do
      contact = ensure_contact!
      contact_inbox = ensure_contact_inbox!(contact)
      conversation = find_conversation || create_conversation!(contact, contact_inbox)
      conversation.reload
      update_conversation!(conversation, timestamp)
      build_voice_message!(conversation, timestamp)
      conversation
    end
  end

  private

  def ensure_contact!
    account.contacts.find_or_create_by!(phone_number: from_number) do |record|
      record.name = from_number if record.name.blank?
    end
  end

  def ensure_contact_inbox!(contact)
    ContactInbox.find_or_create_by!(
      contact_id: contact.id,
      inbox_id: inbox.id
    ) do |record|
      record.source_id = from_number
    end
  end

  def find_conversation
    return if call_sid.blank?

    account.conversations.includes(:contact).find_by(identifier: call_sid)
  end

  def create_conversation!(contact, contact_inbox)
    account.conversations.create!(
      contact_inbox_id: contact_inbox.id,
      inbox_id: inbox.id,
      contact_id: contact.id,
      status: :open,
      identifier: call_sid
    )
  end

  def update_conversation!(conversation, timestamp)
    attrs = {
      'call_direction' => 'inbound',
      'call_status' => 'ringing',
      'conference_sid' => Voice::Conference::Name.for(conversation),
      'meta' => { 'initiated_at' => timestamp }
    }

    conversation.update!(
      identifier: call_sid,
      additional_attributes: attrs,
      last_activity_at: current_time
    )
  end

  def build_voice_message!(conversation, timestamp)
    Voice::CallMessageBuilder.perform!(
      conversation: conversation,
      direction: 'inbound',
      payload: {
        call_sid: call_sid,
        status: 'ringing',
        conference_sid: conversation.additional_attributes['conference_sid'],
        from_number: from_number,
        to_number: inbox.channel&.phone_number
      },
      timestamps: { created_at: timestamp, ringing_at: timestamp }
    )
  end

  def current_timestamp
    @current_timestamp ||= current_time.to_i
  end

  def current_time
    @current_time ||= Time.zone.now
  end
end
