class Crm::Cards::PayloadBuilder
  ATTRIBUTES = %i[
    id pipeline_id stage_id contact_id conversation_id inbox_id owner_id team_id
    title description value_cents currency status lost_reason source priority score metadata external_id
  ].freeze

  TIMESTAMP_FIELDS = %i[
    entered_stage_at last_activity_at last_message_at expected_close_at next_follow_up_at created_at updated_at
  ].freeze

  NESTED_PAYLOADS = {
    contact: :contact_payload,
    owner: :owner_payload,
    responsible: :responsible_payload,
    inbox: :inbox_payload,
    pipeline: :pipeline_payload,
    stage: :stage_payload,
    conversation: :conversation_payload
  }.freeze

  # CTWA multi-touch: aggregates campaign_touches from ALL conversations linked to
  # the card (crm_card_conversations, plus the primary as fallback for legacy cards
  # without a link row), ordered first touch -> last. Slim item (no body/ctwa_clid):
  # {source, source_id, headline, source_url, touched_at, conversation_id}. Single source of
  # truth for the shape — Crm::Kanban::CardPayloadBuilder delegates here so board,
  # list and websocket payloads never drift. Legacy touches without touched_at sort
  # first via to_s -> '' (they are the origin touch, so oldest-first stays correct).
  def self.aggregated_campaigns_for(card)
    conversations = (card.linked_conversations.to_a + [card.primary_conversation]).compact.uniq(&:id)
    conversations.flat_map { |conversation| campaign_touches_for(conversation) }
                 .sort_by { |touch| touch[:touched_at].to_s }
  end

  def self.campaign_touches_for(conversation)
    touches = conversation.additional_attributes&.dig('campaign_touches')
    return [] unless touches.is_a?(Array)

    touches.filter_map do |touch|
      next unless touch.is_a?(Hash)

      {
        source: touch['source'],
        source_id: touch['source_id'],
        headline: touch['headline'],
        source_url: touch['source_url'],
        touched_at: touch['touched_at'],
        conversation_id: conversation.id
      }
    end
  end

  def initialize(card, user: nil, account_user: nil, conversation_visibility: nil)
    @card = card
    @user = user
    @account_user = account_user
    @conversation_visibility = conversation_visibility
  end

  def perform
    ATTRIBUTES.index_with { |attribute| @card.public_send(attribute) }
              .merge(timestamp_payload)
              .tap { |payload| sanitize_hidden_conversation!(payload) }
              .tap { |payload| append_nested_payloads(payload) }
  end

  private

  def sanitize_hidden_conversation!(payload)
    return if primary_conversation_visible?

    payload[:conversation_id] = nil
    payload[:metadata] = sanitized_metadata(payload[:metadata])
  end

  def append_nested_payloads(payload)
    payload[:is_standalone] = @card.standalone?
    payload[:labels] = labels_payload
    payload[:contact_labels] = contact_labels_payload
    payload[:campaigns] = campaigns_payload
    payload[:ai_summary] = ai_summary_payload
    payload[:ai_value] = ai_value_payload
    payload[:handoff_invite] = handoff_invite_payload
    payload[:auto_followup] = auto_followup_payload
    payload[:next_follow_up_source] = next_follow_up_source
    NESTED_PAYLOADS.each do |key, method_name|
      value = send(method_name)
      payload[key] = value if value.present?
    end
  end

  # Label titles (strings) of the PRIMARY conversation only, in cached_label_list
  # order — color/id resolution happens client-side against the labels store.
  # [] when the primary conversation is hidden/absent (same gate as ai_summary).
  # Shape mirrored in Crm::Kanban::CardPayloadBuilder — keep both identical.
  def labels_payload
    return [] unless primary_conversation_visible?

    primary_conversation.cached_label_list_array
  end

  # Label titles of the CONTACT (e.g. campaign import labels — never synced onto
  # the conversation, see CampaignImports::Importer#apply_labels!). Not gated on
  # conversation visibility: the contact itself is always shown on the card.
  # Reads the preloaded label_taggings instead of contact.label_list to avoid an
  # N+1 query per card. Shape mirrored in Crm::Kanban::CardPayloadBuilder — keep
  # both identical.
  def contact_labels_payload
    return [] if @card.contact.blank?

    @card.contact.label_taggings.reject(&:tagger_id).filter_map { |tagging| tagging.tag&.name }
  end

  # See .aggregated_campaigns_for — gated on primary visibility like the summary.
  def campaigns_payload
    return [] unless primary_conversation_visible?

    self.class.aggregated_campaigns_for(@card)
  end

  # Typed AI summary surfaced to the card drawer. Gated on conversation
  # visibility so message-derived content never leaks to agents who cannot
  # see the underlying conversation (also stripped from metadata['ai'] below).
  def ai_summary_payload
    return unless primary_conversation_visible?

    ai_metadata = (@card.metadata || {}).fetch('ai', {})
    text = ai_metadata['summary'].to_s
    return if text.blank?

    {
      text: text,
      generated_at: ai_metadata['summary_generated_at']
    }
  end

  # Provenance of value_cents so the UI can badge "filled by AI" and the Win
  # dialog can hint it. value_cents itself is authoritative (auto-filled).
  # Gated on conversation visibility like the summary.
  # Convite R3 em aberto para o badge do kanban (lógica compartilhada com a
  # lista de conversas em Crm::Ai::HandoffInvitePayload).
  def handoff_invite_payload
    Crm::Ai::HandoffInvitePayload.for_card(@card)
  end

  def ai_value_payload
    return unless primary_conversation_visible?

    ai_metadata = (@card.metadata || {}).fetch('ai', {})
    source = ai_metadata['value_source']
    return if source.blank?

    {
      source: source,
      filled_at: ai_metadata['value_filled_at']
    }
  end

  # AI auto-follow-up cadence state for the card drawer's "Follow-up automático"
  # block. Exposed as a top-level key (not via metadata['ai'], which is stripped
  # for hidden conversations) — it carries only cadence counters/timestamps/
  # template names, no message content or PII, so it is not visibility-gated.
  def auto_followup_payload
    (@card.metadata || {}).dig('ai', 'auto_followup_state').presence
  end

  # Type of the follow-up owning next_follow_up_at (nearest active), so the list
  # row badge can show 🤖 (AI cadence) vs 🔔 (manual) without a per-card query:
  # nearest is the AI touch iff the active cadence's next_due_at == next_follow_up_at.
  def next_follow_up_source
    return if @card.next_follow_up_at.blank?

    state = (@card.metadata || {}).dig('ai', 'auto_followup_state') || {}
    return 'manual' unless state['active'] == true && state['next_due_at'].present?

    Time.zone.parse(state['next_due_at'].to_s).to_i == @card.next_follow_up_at.to_i ? 'ai' : 'manual'
  rescue ArgumentError, TypeError
    'manual'
  end

  def timestamp_payload
    TIMESTAMP_FIELDS.index_with { |field| @card.public_send(field)&.iso8601 }
  end

  def contact_payload
    return if @card.contact.blank?

    {
      id: @card.contact.id,
      name: @card.contact.name,
      phone_number: @card.contact.phone_number,
      email: @card.contact.email,
      # Surfaced so the card drawer can show/edit richer contact data (company,
      # address, city/country, job title…). additional_attributes holds Chatwoot
      # standard keys; custom_attributes holds the non-native ones. Both are merged
      # server-side on update, so the drawer only sends what changed.
      location: @card.contact.location,
      additional_attributes: @card.contact.additional_attributes || {},
      custom_attributes: @card.contact.custom_attributes || {}
    }
  end

  def owner_payload
    return if @card.owner.blank?

    {
      id: @card.owner.id,
      name: @card.owner.name,
      email: @card.owner.email
    }
  end

  def responsible_payload
    @card.responsible_descriptor
  end

  def inbox_payload
    return if @card.inbox.blank?

    {
      id: @card.inbox.id,
      name: @card.inbox.name,
      channel_type: @card.inbox.channel_type
    }
  end

  def pipeline_payload
    return if @card.pipeline.blank?

    {
      id: @card.pipeline.id,
      name: @card.pipeline.name
    }
  end

  def stage_payload
    return if @card.stage.blank?

    {
      id: @card.stage.id,
      name: @card.stage.name,
      position: @card.stage.position,
      color: @card.stage.color
    }
  end

  def conversation_payload
    return if primary_conversation.blank?
    return unless primary_conversation_visible?

    payload = {
      id: primary_conversation.id,
      display_id: primary_conversation.display_id,
      inbox_id: primary_conversation.inbox_id,
      status: primary_conversation.status,
      assignee_id: primary_conversation.assignee_id,
      team_id: primary_conversation.team_id,
      first_reply_created_at: primary_conversation.first_reply_created_at&.to_i,
      waiting_since: primary_conversation.waiting_since&.to_i
    }
    applied_sla = applied_sla_payload
    payload[:applied_sla] = applied_sla if applied_sla.present?
    payload
  end

  # SLA badge data (Kanban/List). Gated on the account 'sla' feature; uses the
  # native push_event_data shape that SLACardLabel/evaluateSLAStatus consume.
  def applied_sla_payload
    return unless @card.account.feature_enabled?('sla')

    primary_conversation.applied_sla&.push_event_data
  end

  def primary_conversation
    @primary_conversation ||= @card.primary_conversation
  end

  def primary_conversation_visible?
    return false if primary_conversation.blank?

    visibility.visible?(primary_conversation)
  end

  def visibility
    @visibility ||= @conversation_visibility || Crm::Conversations::Visibility.new(
      account: @card.account,
      user: @user,
      account_user: @account_user
    )
  end

  # Strip conversation-derived content when the primary conversation is not
  # visible to the requesting user: source_conversation and the AI block
  # (metadata['ai'] holds the conversation summary, which would otherwise leak).
  def sanitized_metadata(metadata)
    return metadata unless metadata.is_a?(Hash)

    metadata.except('source_conversation', 'ai')
  end
end
