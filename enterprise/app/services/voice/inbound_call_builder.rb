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
    existing = find_existing_call
    return existing if existing

    ActiveRecord::Base.transaction do
      contact = ensure_contact!
      contact_inbox = ensure_contact_inbox!(contact)
      conversation = resolve_conversation!(contact, contact_inbox)
      call = create_call!(contact, conversation)
      message = Voice::CallMessageBuilder.new(call).perform!
      call.update!(message_id: message.id)
      call
    end
  rescue ActiveRecord::RecordNotUnique
    # A concurrent Twilio retry won the create race; return what now exists.
    find_existing_call || raise
  end

  private

  def find_existing_call
    Call.where(account_id: account.id, inbox_id: inbox.id)
        .find_by(provider: :twilio, provider_call_id: call_sid)
  end

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

  def resolve_conversation!(contact, contact_inbox)
    if inbox.lock_to_single_conversation
      reusable = account.conversations
                        .where(contact_id: contact.id, inbox_id: inbox.id)
                        .where.not(status: :resolved)
                        .order(last_activity_at: :desc)
                        .first
      return reusable if reusable
    end

    account.conversations.create!(
      contact_inbox_id: contact_inbox.id,
      inbox_id: inbox.id,
      contact_id: contact.id,
      status: :open
    )
  end

  def create_call!(contact, conversation)
    call = Call.create!(
      account: account,
      inbox: inbox,
      conversation: conversation,
      contact: contact,
      provider: :twilio,
      direction: :incoming,
      status: 'ringing',
      provider_call_id: call_sid,
      meta: { 'initiated_at' => Time.zone.now.to_i }
    )
    call.update!(conference_sid: call.default_conference_sid)
    call
  end
end
