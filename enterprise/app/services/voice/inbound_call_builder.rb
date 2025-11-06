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
    ActiveRecord::Base.transaction do
      contact = ensure_contact!
      contact_inbox = ensure_contact_inbox!(contact)
      conversation = find_conversation || create_conversation!(contact, contact_inbox)
      touch_conversation!(conversation)
      build_voice_message!(conversation, contact)
      conversation
    end
  end

  private

  def ensure_contact!
    account.contacts.find_or_create_by!(phone_number: from_number) do |contact|
      contact.name ||= from_number
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
    timestamp = current_timestamp
    attrs = {
      'call_direction' => 'inbound',
      'call_status' => 'ringing',
      'conference_sid' => nil,
      'meta' => { 'initiated_at' => timestamp }
    }

    account.conversations.create!(
      contact_inbox_id: contact_inbox.id,
      inbox_id: inbox.id,
      contact_id: contact.id,
      status: :open,
      identifier: call_sid,
      additional_attributes: attrs
    ).tap do |conversation|
      attrs['conference_sid'] = Voice::Conference::Name.for(conversation)
      conversation.update!(additional_attributes: attrs)
    end
  end

  def touch_conversation!(conversation)
    timestamp = current_timestamp
    attrs = (conversation.additional_attributes || {}).dup
    attrs['call_direction'] = 'inbound'
    attrs['call_status'] = 'ringing'
    attrs['conference_sid'] ||= Voice::Conference::Name.for(conversation)
    attrs['meta'] ||= {}
    attrs['meta']['initiated_at'] ||= timestamp

    updates = { additional_attributes: attrs, last_activity_at: Time.current }
    updates[:identifier] = call_sid if call_sid.present? && conversation.identifier != call_sid
    conversation.update!(updates)
  end

  def build_voice_message!(conversation, _contact)
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
      timestamps: {
        created_at: current_timestamp,
        ringing_at: current_timestamp
      }
    )
  end

  def current_timestamp
    @current_timestamp ||= Time.current.to_i
  end
end
