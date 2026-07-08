class Voice::OutboundCallBuilder
  attr_reader :account, :inbox, :user, :contact

  def self.perform!(account:, inbox:, user:, contact:, conversation: nil)
    new(account: account, inbox: inbox, user: user, contact: contact, conversation: conversation).perform!
  end

  def initialize(account:, inbox:, user:, contact:, conversation: nil)
    @account = account
    @inbox = inbox
    @user = user
    @contact = contact
    @existing_conversation = conversation
  end

  def perform!
    raise ArgumentError, 'Contact phone number required' if contact.phone_number.blank?
    raise ArgumentError, 'Agent required' if user.blank?

    # Claim for the caller if a reused conversation is unassigned at trigger time; wins over auto-assignment.
    # New conversations set the assignee at creation instead (see create_conversation!).
    claim_for_caller = @existing_conversation && @existing_conversation.assignee_id.nil?

    ActiveRecord::Base.transaction do
      contact_inbox = ensure_contact_inbox!
      conversation = @existing_conversation || create_conversation!(contact_inbox)
      # Dial before locking so the Twilio round-trip doesn't hold the conversation row lock.
      call_sid = initiate_call!
      if claim_for_caller
        @existing_conversation.lock!
        @existing_conversation.update!(assignee: user)
      end
      call = create_call!(conversation, call_sid)
      message = Voice::CallMessageBuilder.new(call).perform!
      call.update!(message_id: message.id)
      call
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
    account.conversations.create!(
      contact_inbox_id: contact_inbox.id,
      inbox_id: inbox.id,
      contact_id: contact.id,
      assignee_id: user.id,
      status: :open
    )
  end

  def initiate_call!
    inbox.channel.initiate_call(to: contact.phone_number)[:call_sid]
  end

  def create_call!(conversation, call_sid)
    call = Call.create!(
      account: account,
      inbox: inbox,
      conversation: conversation,
      contact: contact,
      accepted_by_agent: user,
      provider: :twilio,
      direction: :outgoing,
      status: 'ringing',
      provider_call_id: call_sid,
      meta: { 'initiated_at' => Time.zone.now.to_i }
    )
    call.update!(conference_sid: call.default_conference_sid)
    call
  end
end
