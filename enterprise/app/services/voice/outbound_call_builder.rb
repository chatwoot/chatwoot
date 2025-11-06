class Voice::OutboundCallBuilder
  attr_reader :account, :inbox, :user, :contact

  def self.perform!(account:, inbox:, user:, contact:)
    new(account: account, inbox: inbox, user: user, contact: contact).perform!
  end

  def initialize(account:, inbox:, user:, contact:)
    @account = account
    @inbox = inbox
    @user = user
    @contact = contact
  end

  def perform!
    raise ArgumentError, 'Contact phone number required' if contact.phone_number.blank?
    raise ArgumentError, 'Agent required' if user.blank?

    ActiveRecord::Base.transaction do
      contact_inbox = ensure_contact_inbox!
      conversation = create_conversation!(contact_inbox)
      conference_sid = conversation.additional_attributes['conference_sid']
      call_sid = initiate_call!
      finalize_conversation!(conversation, call_sid)
      build_voice_message!(conversation, call_sid, conference_sid)
      { conversation: conversation, call_sid: call_sid }
    end
  end

  private

  def ensure_contact_inbox!
    ContactInbox.find_or_create_by!(
      contact_id: contact.id,
      inbox_id: inbox.id
    ) do |record|
      record.source_id = contact.phone_number
    end
  end

  def create_conversation!(contact_inbox)
    timestamp = current_timestamp
    attrs = {
      'call_direction' => 'outbound',
      'call_status' => 'ringing',
      'agent_id' => user.id,
      'conference_sid' => nil,
      'meta' => { 'initiated_at' => timestamp }
    }

    account.conversations.create!(
      contact_inbox_id: contact_inbox.id,
      inbox_id: inbox.id,
      contact_id: contact.id,
      status: :open,
      additional_attributes: attrs
    ).tap do |conversation|
      attrs['conference_sid'] = Voice::Conference::Name.for(conversation)
      conversation.update!(additional_attributes: attrs)
    end
  end

  def initiate_call!
    inbox.channel.initiate_call(
      to: contact.phone_number
    )[:call_sid]
  end

  def finalize_conversation!(conversation, call_sid)
    attrs = (conversation.additional_attributes || {}).dup
    attrs['call_direction'] = 'outbound'
    attrs['call_status'] = 'ringing'
    attrs['agent_id'] = user.id
    attrs['conference_sid'] ||= Voice::Conference::Name.for(conversation)
    attrs['meta'] ||= {}
    attrs['meta']['initiated_at'] ||= current_timestamp
    conversation.update!(
      identifier: call_sid,
      additional_attributes: attrs,
      last_activity_at: Time.current
    )
  end

  def build_voice_message!(conversation, call_sid, conference_sid)
    Voice::CallMessageBuilder.perform!(
      conversation: conversation,
      direction: 'outbound',
      payload: {
        call_sid: call_sid,
        status: 'ringing',
        conference_sid: conference_sid,
        from_number: inbox.channel&.phone_number,
        to_number: contact.phone_number
      },
      user: user,
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
