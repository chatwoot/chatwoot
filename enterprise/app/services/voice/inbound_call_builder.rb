class Voice::InboundCallBuilder
  attr_reader :inbox, :from_number, :call_sid, :provider, :extra_meta

  def self.perform!(inbox:, from_number:, call_sid:, provider: :twilio, extra_meta: {})
    new(inbox: inbox, from_number: from_number, call_sid: call_sid,
        provider: provider, extra_meta: extra_meta).perform!
  end

  def initialize(inbox:, from_number:, call_sid:, provider: :twilio, extra_meta: {})
    @inbox = inbox
    @from_number = from_number
    @call_sid = call_sid
    @provider = provider.to_sym
    @extra_meta = extra_meta || {}
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

  # Always look up by (inbox, source_id) first — that pair has a UNIQUE index, so
  # creating with a colliding source_id under a different contact would raise
  # RecordNotUnique. Reuse the existing ContactInbox (and its contact) when found.
  # A concurrent message webhook for the same wa_id can win the (inbox_id, source_id)
  # race; rescue and re-find so the call path doesn't drop the connect.
  def ensure_contact_inbox!
    sid = source_id_for_provider
    existing = inbox.contact_inboxes.find_by(source_id: sid)
    return existing if existing

    ContactInbox.create!(contact: ensure_contact!, inbox: inbox, source_id: sid)
  rescue ActiveRecord::RecordNotUnique
    inbox.contact_inboxes.find_by!(source_id: sid)
  end

  def ensure_contact!
    account.contacts.find_or_create_by!(phone_number: from_number) do |record|
      record.name = from_number if record.name.blank?
    end
  end

  # WhatsApp ContactInbox.source_id must be digits-only (the wa_id); Twilio accepts the +.
  # Run BR/AR-style wa_id normalization (same path messaging uses) so an inbound call
  # finds the existing ContactInbox instead of forking a new contact/conversation.
  def source_id_for_provider
    return from_number unless provider == :whatsapp

    digits = from_number.to_s.delete_prefix('+')
    Whatsapp::PhoneNumberNormalizationService.new(inbox).normalize_and_find_contact_by_provider(digits, :cloud)
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
