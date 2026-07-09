class Crm::Kanban::BoardPayloadBuilder
  include Crm::Cards::SharedFilters

  DEFAULT_LIMIT_PER_STAGE = 50
  MAX_LIMIT_PER_STAGE = 100

  def initialize(pipeline:, cards_scope:, context:)
    @pipeline = pipeline
    @cards_scope = cards_scope
    @params = context.params
    @conversation_visibility = Crm::Conversations::Visibility.new(
      account: context.account,
      user: context.user,
      account_user: context.account_user
    )
  end

  def perform
    {
      pipeline: pipeline_payload,
      stages: stages.map { |stage| stage_payload(stage, board_pending_suggestions) }
    }
  end

  private

  def stages
    scope = @pipeline.stages.order(:position, :id)
    requested_stage_ids.present? ? scope.where(id: requested_stage_ids) : scope
  end

  def stage_payload(stage, pending_suggestions)
    base_scope = filtered_cards.where(stage_id: stage.id)
    cards, has_more = cards_for_stage(base_scope, stage)

    {
      id: stage.id,
      name: stage.name,
      position: stage.position,
      color: stage.color,
      wip_limit: stage.wip_limit,
      sla_seconds: stage.sla_seconds,
      cards_count: include_counts? ? base_scope.count : nil,
      cards: cards.map { |card| card_payload(card, pending_suggestions) },
      has_more: has_more,
      next_cursor: next_cursor_for(cards, has_more)
    }
  end

  def filtered_cards
    @filtered_cards ||= apply_standalone_filter(apply_param_filters(base_cards_scope))
  end

  def base_cards_scope
    @cards_scope.open.where(pipeline_id: @pipeline.id)
  end

  def apply_param_filters(cards)
    cards = cards.where(inbox_id: @params[:inbox_id]) if @params[:inbox_id].present?
    cards = cards.where(owner_id: @params[:owner_id]) if @params[:owner_id].present?
    cards = cards.where(priority: @params[:priority]) if @params[:priority].present?
    apply_follow_up_filter(apply_search_filter(apply_shared_filters(cards)))
  end

  # High-value filters shared verbatim with Crm::Cards::FilterQuery (list view) so
  # board and list agree. stage_ids is already applied per-stage in #stages but kept
  # here too so the shared contract stays single-sourced.
  def apply_shared_filters(cards)
    cards = apply_team_filter(cards)
    cards = apply_value_range_filter(cards)
    cards = apply_stale_filter(cards)
    cards = apply_responsible_filter(cards)
    cards = apply_label_filter(cards)
    cards = apply_campaign_filter(cards)
    apply_ai_pending_filter(cards)
  end

  def apply_search_filter(cards)
    return cards if @params[:search].blank?

    search_term = ActiveRecord::Base.sanitize_sql_like(@params[:search].strip.downcase)
    cards.where('LOWER(crm_cards.title) LIKE ?', "%#{search_term}%")
  end

  def apply_standalone_filter(cards)
    return cards.standalone if @params[:standalone].to_s == 'true'
    return cards.linked if @params[:standalone].to_s == 'false'

    cards
  end

  def apply_follow_up_filter(cards)
    case @params[:follow_up_status].presence
    when 'none'
      cards.where(next_follow_up_at: nil)
    when 'pending'
      cards.where.not(next_follow_up_at: nil).where('crm_cards.next_follow_up_at >= ?', Time.current)
    when 'overdue'
      cards.where.not(next_follow_up_at: nil).where('crm_cards.next_follow_up_at < ?', Time.current)
    else
      cards
    end
  end

  def pipeline_payload
    {
      id: @pipeline.id,
      name: @pipeline.name,
      description: @pipeline.description,
      position: @pipeline.position
    }
  end

  def card_payload(card, pending_suggestions = {})
    Crm::Kanban::CardPayloadBuilder.new(
      card: card,
      conversation_visibility: @conversation_visibility,
      pending_suggestion: pending_suggestions[card.id]
    ).perform
  end

  def board_pending_suggestions
    return {} unless Crm::Ai::Config.enabled?

    card_ids = filtered_cards.pluck(:id)
    return {} if card_ids.blank?

    Crm::AiStageSuggestion
      .includes(:to_stage)
      .where(account_id: @pipeline.account_id, card_id: card_ids, status: :pending)
      .order(created_at: :desc)
      .group_by(&:card_id)
      .transform_values(&:first)
  end

  def cards_for_stage(base_scope, stage)
    cards_scope = base_scope.order(id: :desc)
    cards_scope = cards_scope.where('crm_cards.id < ?', cursor_for(stage)) if cursor_for(stage).present?
    cards = cards_scope.preload(
      :owner, :linked_conversations,
      { contact: { label_taggings: :tag } },
      { inbox: { agent_bot_inbox: :agent_bot } },
      { primary_conversation: [:conversation_participants, :assignee, { applied_sla: :sla_policy }, { inbox: { agent_bot_inbox: :agent_bot } }] }
    ).limit(limit_per_stage + 1).to_a
    [cards.first(limit_per_stage), cards.size > limit_per_stage]
  end

  def cursor_for(stage)
    cursor_by_stage[stage.id.to_s].presence
  end

  def next_cursor_for(cards, has_more)
    cards.last.id if has_more
  end

  def cursor_by_stage
    @cursor_by_stage ||= @params[:cursor_by_stage].is_a?(ActionController::Parameters) ? @params[:cursor_by_stage].to_unsafe_h : {}
  end

  def requested_stage_ids
    return @requested_stage_ids if defined?(@requested_stage_ids)

    raw_stage_ids = @params[:stage_ids].presence || @params[:stage_id].presence
    @requested_stage_ids = Array(raw_stage_ids)
                           .flat_map { |stage_id| stage_id.to_s.split(',') }
                           .filter_map { |stage_id| Integer(stage_id, exception: false) }
                           .uniq
  end

  def limit_per_stage
    requested_limit = @params[:limit_per_stage].presence&.to_i
    return DEFAULT_LIMIT_PER_STAGE if requested_limit.blank?

    requested_limit.clamp(1, MAX_LIMIT_PER_STAGE)
  end

  def include_counts?
    ActiveModel::Type::Boolean.new.cast(@params[:include_counts])
  end
end
