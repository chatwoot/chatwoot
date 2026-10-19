class Voice::InboundCallBuilder
  attr_reader :inbox, :call_sid, :provider, :extra_meta, :source_ids, :contact_attributes

  # `caller` carries the contact identity: { source_ids:, contact_attributes: }. Twilio passes
  # its single +phone source_id; WhatsApp passes the message-path phone/user_id/parent_user_id set.
  def self.perform!(inbox:, call_sid:, caller:, provider: :twilio, extra_meta: {})
    new(inbox: inbox, call_sid: call_sid, caller: caller, provider: provider, extra_meta: extra_meta).perform!
  end

  # Queues the ring of a call that recorded who it rings and has no outcome for that ring
  # yet: when the call is created, and again when a retried inbound event finds it, as when
  # queueing the first job failed or its worker stopped. A ring still under way makes the
  # extra job wait for it.
  def self.queue_ring(call)
    return unless call.ringing? && call.ring_state.key?('ring_recipient_ids') && !call.ring_state.key?('unreached_user_ids')

    ActiveRecord.after_all_transactions_commit { Voice::VoipPushJob.perform_later(call.id, 'ring') }
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
    # A retry of the inbound event queues the ring again if the call recorded who it rings
    # but its ring never went out
    return existing.tap { |call| self.class.queue_ring(call) } if existing

    ActiveRecord::Base.transaction do
      contact_inbox = ensure_contact_inbox!
      contact = contact_inbox.contact
      conversation = resolve_conversation!(contact, contact_inbox)
      created = create_call!(contact, conversation)
      message = Voice::CallMessageBuilder.new(created).perform!
      created.update!(message_id: message.id)
      record_ring_audience(created)
      ring_phones(created)
      created
    end
  rescue ActiveRecord::RecordNotUnique
    # A concurrent provider retry won the create race; return what now exists.
    find_existing_call || raise
  end

  private

  def account
    inbox.account
  end

  # Phones without a live socket learn about the call through a push. The agents rung are
  # recorded in the transaction that creates the call, so the push and a missed-call notice
  # go to the same agents even when the conversation is reassigned before the job runs, and
  # a call the caller ends as soon as it is visible still has them.
  def record_ring_audience(call)
    return unless account.feature_enabled?('channel_voice') && account.feature_enabled?('mobile_voice_push')

    recipient_ids = Voice::VoipPushService.recipients_for(call).map(&:id)
    call.update_columns(ring_state: call.ring_state.merge('ring_recipient_ids' => recipient_ids)) # rubocop:disable Rails/SkipsModelValidations
  end

  # Registered in the transaction that records the audience, so the job is queued with it.
  # The job runs once the call row is visible to the worker, which otherwise finds nothing
  # to ring for.
  def ring_phones(call) = self.class.queue_ring(call)

  def find_existing_call
    Call.where(account_id: account.id, inbox_id: inbox.id)
        .find_by(provider: provider, provider_call_id: call_sid)
  end

  # Resolve the contact/ContactInbox the same way inbound messages do — match across every
  # candidate source_id (phone + BSUID aliases) so a call reuses the existing contact. Shared
  # with messaging via ContactInboxSourceIdResolver, which also rescues the concurrent-webhook
  # create race.
  #
  # WhatsApp asks for the preferred alias so a call lands on the exact BSUID ContactInbox, the
  # same one a message resolves; without it a legacy caller would keep answering through the
  # phone row while messages moved on. Twilio has a single phone identity and opts out.
  def ensure_contact_inbox!
    ContactInboxSourceIdResolver.new(
      inbox: inbox, source_ids: source_ids, contact_attributes: contact_attributes,
      prefer_first_source_id: whatsapp_provider?
    ).perform
  end

  def resolve_conversation!(contact, contact_inbox)
    reusable = reusable_conversation(contact_inbox)
    return reusable if reusable

    account.conversations.create!(
      contact_inbox_id: contact_inbox.id,
      inbox_id: inbox.id,
      contact_id: contact.id,
      status: :open
    )
  end

  # Scoped to the resolved ContactInbox, never to the contact. A dashboard merge leaves unrelated
  # WhatsApp identities on the same contact, and a contact-wide lookup cannot tell them apart: it
  # would answer a call through another identity's source_id. The conversation opened under a
  # previous identity stays where it is, reachable under previous conversations.
  def reusable_conversation(contact_inbox)
    conversations = contact_inbox.conversations
    return conversations.last if inbox.lock_to_single_conversation

    conversations.where.not(status: :resolved).last
  end

  def whatsapp_provider?
    provider == :whatsapp
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
