# Shared filter predicates for CRM cards so the board (Crm::Kanban::BoardPayloadBuilder)
# and the list (Crm::Cards::FilterQuery) agree on every server-side filter. Adding a
# filter to only one path re-creates the historical "Status" board/list divergence, so
# every new param MUST be honored here and mirrored client-side in cardMatchesFilters
# (crmKanban.js) OR force a refetch-on-realtime. Per-filter realtime contract:
#   * client-predicate (mirrored in cardMatchesFilters): stage_ids, value_min/value_max,
#     stale_days, standalone, team_id, priority, inbox_id, owner_id, search, follow_up,
#     campaign_source_ids (mirrored via card.campaigns.some(t => ids.includes(t.source_id))).
#   * server-only + refetch-on-realtime (cannot be derived from a single upsert payload):
#     responsible_kind (bot/none rely on the agent_bot_inbox join + conversation assignee),
#     ai_pending (the pending-suggestion set is computed per board load) and label_ids
#     (matches taggings of the primary conversation, source of truth for labels).
module Crm::Cards::SharedFilters
  RESPONSIBLE_KINDS = %w[agent bot none].freeze

  def apply_stage_ids_filter(cards)
    ids = parse_stage_ids
    return cards if ids.blank?

    cards.where(stage_id: ids)
  end

  def apply_value_range_filter(cards)
    cards = cards.where('crm_cards.value_cents >= ?', value_cents_param(:value_min)) if value_cents_param(:value_min)
    cards = cards.where('crm_cards.value_cents <= ?', value_cents_param(:value_max)) if value_cents_param(:value_max)
    cards
  end

  # No real message AND no stage movement in N days (GREATEST is NULL-safe).
  def apply_stale_filter(cards)
    days = @params[:stale_days].presence&.to_i
    return cards if days.blank? || days <= 0

    stale_sql = 'GREATEST(crm_cards.last_message_at, crm_cards.entered_stage_at)'
    cards.where("#{stale_sql} IS NULL OR #{stale_sql} < ?", days.days.ago)
  end

  def apply_team_filter(cards)
    return cards if @params[:team_id].blank?

    cards.where(team_id: @params[:team_id])
  end

  def apply_ai_pending_filter(cards)
    return cards unless ActiveModel::Type::Boolean.new.cast(@params[:ai_pending])

    cards.where(id: Crm::AiStageSuggestion.where(status: :pending).select(:card_id))
  end

  # responsible_kind maps the realtime "responsible" descriptor to SQL:
  #   agent -> a human is responsible (linked conversation assignee, or owner when standalone)
  #   bot   -> no human responsible, but the resolved inbox has an active agent bot
  #   none  -> no human responsible and no active agent bot
  def apply_responsible_filter(cards)
    kind = @params[:responsible_kind].to_s
    return cards unless RESPONSIBLE_KINDS.include?(kind)

    scoped = cards
             .joins('LEFT JOIN conversations ON conversations.id = crm_cards.conversation_id')
             .joins('LEFT JOIN agent_bot_inboxes ON agent_bot_inboxes.inbox_id = ' \
                    'COALESCE(conversations.inbox_id, crm_cards.inbox_id) AND agent_bot_inboxes.status = 0')
    case kind
    when 'agent'
      scoped.where(human_responsible_sql)
    when 'bot'
      scoped.where("NOT (#{human_responsible_sql})").where.not(agent_bot_inboxes: { id: nil })
    when 'none'
      scoped.where("NOT (#{human_responsible_sql})").where(agent_bot_inboxes: { id: nil })
    end
  end

  # Campaign filter (CTWA multi-touch): campaign_source_ids is a csv of ad source_ids
  # with OR semantics — a card matches when ANY touch of ANY linked conversation
  # (crm_card_conversations OR the direct primary conversation_id) hits any of the ids.
  # It probes the `campaign_source_ids` jsonb-array mirror rendered as text with a
  # quoted token (ILIKE '%"<id>"%'), so substrings of other ids never false-positive
  # and the trigram index on the mirror is used. Standalone cards (no conversations)
  # are always excluded.
  def apply_campaign_filter(cards)
    source_ids = parse_campaign_source_ids
    return cards if source_ids.blank?

    tokens = source_ids.map { |source_id| "%\"#{ActiveRecord::Base.sanitize_sql_like(source_id)}\"%" }
    mirror_predicates = tokens.map { "conversations.additional_attributes ->> 'campaign_source_ids' ILIKE ?" }
    cards.where(<<~SQL.squish, *tokens)
      EXISTS (
        SELECT 1 FROM conversations
        WHERE conversations.account_id = crm_cards.account_id
          AND (conversations.id = crm_cards.conversation_id
               OR conversations.id IN (SELECT ccc.conversation_id FROM crm_card_conversations ccc WHERE ccc.card_id = crm_cards.id))
          AND (#{mirror_predicates.join(' OR ')})
      )
    SQL
  end

  # Label filter: label_ids is a csv of Label ids (OR semantics) matched against the
  # PRIMARY conversation only (mirrors the card `labels` payload). Chatwoot labels are
  # acts-as-taggable tags — the account-scoped Label row is metadata whose `title`
  # equals `tags.name` — so the join goes Label(id) -> title -> tags.name -> taggings
  # of the conversation. EXISTS keeps one row per card (no duplicate when a
  # conversation carries several of the selected labels).
  def apply_label_filter(cards)
    label_ids = parse_label_ids
    return cards if label_ids.blank?

    cards.where(<<~SQL.squish, label_ids)
      EXISTS (
        SELECT 1 FROM taggings
        INNER JOIN tags ON tags.id = taggings.tag_id
        INNER JOIN labels ON labels.title = tags.name AND labels.account_id = crm_cards.account_id
        WHERE taggings.taggable_type = 'Conversation'
          AND taggings.context = 'labels'
          AND taggings.taggable_id = crm_cards.conversation_id
          AND labels.id IN (?)
      )
    SQL
  end

  private

  # A human is responsible when the linked conversation has an assignee, or (for cards
  # without a linked conversation) when an owner is set. Mirrors Crm::Card#responsible_descriptor.
  def human_responsible_sql
    '(crm_cards.conversation_id IS NOT NULL AND conversations.assignee_id IS NOT NULL) OR ' \
      '(crm_cards.conversation_id IS NULL AND crm_cards.owner_id IS NOT NULL)'
  end

  def parse_stage_ids
    Array(@params[:stage_ids].presence || @params[:stage_id].presence)
      .flat_map { |stage_id| stage_id.to_s.split(',') }
      .filter_map { |stage_id| Integer(stage_id, exception: false) }
      .uniq
  end

  def parse_label_ids
    Array(@params[:label_ids].presence)
      .flat_map { |label_id| label_id.to_s.split(',') }
      .filter_map { |label_id| Integer(label_id, exception: false) }
      .uniq
  end

  # source_ids are opaque Meta ad ids — keep them as strings (never Integer-cast).
  def parse_campaign_source_ids
    Array(@params[:campaign_source_ids].presence)
      .flat_map { |source_id| source_id.to_s.split(',') }
      .map(&:strip)
      .reject(&:blank?)
      .uniq
  end

  def value_cents_param(key)
    raw = @params[key]
    return if raw.blank?

    Integer(raw, exception: false)
  end
end
