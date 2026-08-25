class Voice::InboundCallBuilder
  attr_reader :inbox, :call_sid, :provider, :extra_meta, :source_ids, :contact_attributes

  # `caller` carries the contact identity: { source_ids:, contact_attributes: }. Twilio passes
  # its single +phone source_id; WhatsApp passes the message-path phone/user_id/parent_user_id set.
  def self.perform!(inbox:, call_sid:, caller:, provider: :twilio, extra_meta: {})
    new(inbox: inbox, call_sid: call_sid, caller: caller, provider: provider, extra_meta: extra_meta).perform!
  end

  def initialize(inbox:, call_sid:, caller:, provider: :twilio, extra_meta: {})
    @inbox = inbox
    @call_sid = call_sid
    @provider = provider.to_sym
    @extra_meta = extra_meta || {}
    @source_ids = Array(caller[:source_ids]).compact_blank
    @contact_attributes = caller[:contact_attributes] || {}
  end

  def perform!
    existing = find_existing_call
    return existing if existing

    ActiveRecord::Base.transaction do
      contact_inbox = ensure_contact_inbox!
      contact = contact_inbox.contact
      conversation = resolve_conversation!(contact, contact_inbox)
      call = create_call!(contact, conversation)
      message = Voice::CallMessageBuilder.new(call).perform!
      call.update!(message_id: message.id)
      call
    end
  rescue ActiveRecord::RecordNotUnique
    # A concurrent provider retry won the create race; return what now exists.
    find_existing_call || raise
  end

  private

  def account
    inbox.account
  end

  def find_existing_call
    Call.where(account_id: account.id, inbox_id: inbox.id)
        .find_by(provider: provider, provider_call_id: call_sid)
  end

  # Resolve the contact/ContactInbox the same way inbound messages do — match across every
  # candidate source_id (phone + BSUID aliases) so a call reuses the existing thread, creating
  # one keyed on the first (phone, else BSUID) only when none exists. Shared with messaging via
  # ContactInboxSourceIdResolver, which also rescues the concurrent-webhook create race.
  def ensure_contact_inbox!
    ContactInboxSourceIdResolver.new(
      inbox: inbox, source_ids: source_ids, contact_attributes: contact_attributes
    ).perform
  end

  # Mirror Whatsapp::IncomingMessageBaseService#set_conversation: reuse this row's open conversation (or last when locked), else create.
  def resolve_conversation!(contact, contact_inbox)
    reusable = if inbox.lock_to_single_conversation
                 contact_inbox.conversations.last
               else
                 contact_inbox.conversations.where.not(status: :resolved).last
               end
    return reusable if reusable

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
      provider: provider,
      direction: :incoming,
      status: 'ringing',
      provider_call_id: call_sid,
      meta: { 'initiated_at' => Time.zone.now.to_i }.merge(extra_meta.stringify_keys)
    )
    # `conference_sid` is a Twilio bridging concept; WhatsApp goes browser↔Meta.
    call.update!(conference_sid: call.default_conference_sid) if call.twilio?
    call
  end
end
