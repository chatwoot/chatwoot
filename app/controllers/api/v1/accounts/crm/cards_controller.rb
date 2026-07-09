class Api::V1::Accounts::Crm::CardsController < Api::V1::Accounts::Crm::BaseController
  include Crm::IdempotentRequests

  before_action :fetch_card, only: [
    :show, :update, :destroy, :move, :close, :link_conversation, :unlink_conversation, :link_contact, :unlink_contact,
    :current_ai_suggestion, :evaluate_ai, :summarize, :reset_auto_followup
  ]
  before_action :ensure_crm_ai_enabled, only: [:current_ai_suggestion, :evaluate_ai, :summarize, :reset_auto_followup]

  RESULTS_PER_PAGE = 25
  MAX_RESULTS_PER_PAGE = 100

  def index
    authorize ::Crm::Card
    # Ordering is owned by FilterQuery#apply_sort (whitelisted sort/direction,
    # defaulting to updated_at desc — byte-identical to the historical default).
    @cards = filtered_cards.page(params[:page] || 1).per(per_page)
    @cards_count = filtered_cards.count
  end

  def show; end

  def by_conversation
    # Chatwoot's frontend identifies conversations by display_id (per-account).
    conversation = Current.account.conversations.find_by!(display_id: params[:conversation_id])
    authorize_crm_conversation!(conversation)
    card = ::Crm::Cards::ConversationCardFinder.new(account: Current.account).find(conversation)
    render json: { payload: stage_badge_payload(card) }
  end

  # Bulk stage lookup for the conversation list (virtual stage chips). Returns
  # { conversation_id => stage_badge } only for conversations the requester can
  # see that have an OPEN card. Capped at 100 ids per call.
  def card_stages
    # Frontend sends display_ids (Chatwoot's per-account conversation identifier);
    # respond keyed by the SAME display_id so the client can match.
    display_ids = Array(params[:conversation_ids]).filter_map { |id| id.to_s[/\d+/]&.to_i }.uniq.first(100)
    return render(json: { payload: {} }) if display_ids.blank?

    conversations = Current.account.conversations.where(display_id: display_ids)
                           .select { |conversation| crm_visibility.visible?(conversation) }
    return render(json: { payload: {} }) if conversations.blank?

    display_by_global = conversations.index_by(&:id).transform_values(&:display_id)
    multiple = Current.account.crm_pipelines.count > 1
    payload = ::Crm::Card.open
                         .where(account_id: Current.account.id, conversation_id: conversations.map(&:id))
                         .includes(:stage, :pipeline)
                         .each_with_object({}) do |card, acc|
      next if card.stage.blank?

      display_id = display_by_global[card.conversation_id]
      next if display_id.blank?

      acc[display_id] = stage_badge_payload(card).merge(multiple_pipelines: multiple)
    end
    render json: { payload: payload }
  end

  def create
    with_idempotency do
      authorize ::Crm::Card
      permitted_params = create_params.to_h.with_indifferent_access
      external_id = permitted_params[:external_id].presence

      # Idempotent upsert for external systems (n8n): a retried create with the
      # same external_id updates the existing card instead of duplicating.
      existing = external_id && Current.account.crm_cards.find_by(external_id: external_id)
      next upsert_existing_card!(existing, permitted_params) if existing

      conversation = conversation_from_params(permitted_params)
      resolved_params = resolved_create_params(permitted_params, conversation: conversation)
      create_authorizer.authorize!(resolved_params, conversation: conversation)
      @card = ::Crm::Cards::Creator.new(account: Current.account, user: Current.user, params: resolved_params, conversation: conversation).perform
      authorize @card, :show?
      broadcast_card(::Events::Types::CRM_CARD_CREATED)
      render :show, status: :created
    rescue ActiveRecord::RecordNotUnique
      # Lost a race on the same external_id — resolve to the now-existing card.
      raise unless external_id

      upsert_existing_card!(Current.account.crm_cards.find_by!(external_id: external_id), permitted_params)
    end
  end

  def from_conversation
    authorize ::Crm::Card, :from_conversation?
    conversation = conversation_for_from_conversation!
    authorize_crm_conversation!(conversation)
    result = from_conversation_handler(conversation).perform { |card| authorize card, :show? }

    @card = result.card
    broadcast_card(::Events::Types::CRM_CARD_CREATED) if result.created
    render :show, status: result.created ? :created : :ok
  end

  def update
    attributes = update_params.to_h.with_indifferent_access
    strip_ai_metadata!(attributes)
    if attributes.present?
      mark_value_source_human!(attributes) if attributes.key?(:value_cents)
      @card.update!(attributes)
      ::Crm::ActivityLogger.new(card: @card, actor: Current.user, event_type: 'update', payload: attributes).perform
      broadcast_card(::Events::Types::CRM_CARD_UPDATED)
    end
    render :show
  end

  def destroy
    @card.update!(status: :archived, last_activity_at: Time.current)
    ::Crm::ActivityLogger.new(card: @card, actor: Current.user, event_type: 'archive', payload: {}).perform
    broadcast_card(::Events::Types::CRM_CARD_ARCHIVED)
    render :show
  end

  def move
    with_idempotency do
      target_stage = Current.account.crm_pipeline_stages.find(params[:stage_id])
      @card = ::Crm::Cards::Mover.new(card: @card, actor: Current.user, target_stage: target_stage).perform
      broadcast_card(::Events::Types::CRM_CARD_MOVED)
      render :show
    end
  end

  def close
    with_idempotency do
      @card = ::Crm::Cards::Closer.new(
        card: @card,
        actor: Current.user,
        result: params[:result],
        value_cents: params[:value_cents],
        currency: params[:currency],
        lost_reason: params[:lost_reason]
      ).perform
      broadcast_card(::Events::Types::CRM_CARD_UPDATED)
      render :show
    rescue ::Crm::Cards::Closer::InvalidResult
      render json: { error: 'invalid_result' }, status: :unprocessable_entity
    end
  end

  def link_conversation
    conversation = Current.account.conversations.find(params[:conversation_id])
    authorize_crm_conversation!(conversation)
    @card = ::Crm::Cards::ConversationLinker.new(
      card: @card,
      conversation: conversation,
      actor: Current.user,
      primary: ActiveModel::Type::Boolean.new.cast(params[:primary])
    ).link
    broadcast_card(::Events::Types::CRM_CARD_UPDATED)
    render :show
  end

  def unlink_conversation
    conversation = Current.account.conversations.find(params[:conversation_id])
    authorize_crm_conversation!(conversation)
    @card = ::Crm::Cards::ConversationLinker.new(card: @card, conversation: conversation, actor: Current.user).unlink
    broadcast_card(::Events::Types::CRM_CARD_UPDATED)
    render :show
  end

  def link_contact
    contact = Current.account.contacts.find(params[:contact_id])
    @card = ::Crm::Cards::ContactLinker.new(card: @card, contact: contact, actor: Current.user).link
    broadcast_card(::Events::Types::CRM_CARD_UPDATED)
    render :show
  end

  def unlink_contact
    @card = ::Crm::Cards::ContactLinker.new(card: @card, contact: @card.contact, actor: Current.user).unlink
    broadcast_card(::Events::Types::CRM_CARD_UPDATED)
    render :show
  end

  def current_ai_suggestion
    @ai_suggestion = @card.account.crm_ai_stage_suggestions.current_pending.find_by(card: @card)
    render json: { payload: ai_suggestion_payload(@ai_suggestion) }
  end

  def evaluate_ai
    result = Crm::Ai::Evaluator.new(card: @card, trigger: 'manual').perform
    @ai_suggestion = result.suggestion
    render json: {
      payload: {
        status: result.status,
        suggestion: ai_suggestion_payload(@ai_suggestion)
      }
    }
  end

  def summarize
    # The summary is derived from the conversation's messages, so gate on the
    # same conversation visibility used elsewhere to avoid leaking content to
    # agents who cannot see the underlying conversation.
    authorize_crm_conversation!(@card.primary_conversation) if @card.primary_conversation.present?
    result = Crm::Ai::ConversationSummarizer.new(card: @card, force: true).perform
    render json: {
      payload: {
        status: result.status,
        error: result.error,
        ai_summary: result.text.present? ? { text: result.text, generated_at: result.generated_at } : nil
      }
    }
  end

  # Re-arms a fresh AI auto-follow-up cadence on a card whose previous cycle was
  # spent (reached max_touches, was stopped, or skipped). Cancels any still-active
  # ai_followup touches, clears the cadence state to an un-armed shape so the next
  # planner sweep starts a new cycle, then broadcasts the updated card.
  def reset_auto_followup
    @card.follow_ups.active.find_each do |follow_up|
      follow_up.update!(status: :canceled) if follow_up.metadata.to_h['source'] == 'ai_followup'
    end

    metadata = (@card.metadata || {}).deep_dup
    metadata['ai'] ||= {}
    metadata['ai']['auto_followup_state'] = {
      'active' => false, 'spent' => false, 'touch' => 0,
      'stopped_reason' => nil, 'opted_out' => false,
      'next_due_at' => nil, 'last_sent_at' => nil,
      'last_marketing_template_sent_at' => nil, 'touches' => []
    }
    @card.update!(metadata: metadata)

    ::Crm::ActivityLogger.new(
      card: @card, actor: Current.user, event_type: 'ai_followup_reset',
      conversation: @card.primary_conversation, payload: {}
    ).perform
    broadcast_card(::Events::Types::CRM_CARD_UPDATED)
    render :show
  end

  private

  # Business fields an external upsert may set on an existing card. Excludes
  # status (goes through #close) and metadata (server-owned 'ai' block).
  UPSERT_ATTRIBUTES = %i[
    title description value_cents currency lost_reason source priority score
    expected_close_at pipeline_id stage_id owner_id team_id contact_id
  ].freeze

  def upsert_existing_card!(card, permitted_params)
    @card = card
    authorize @card, :update?
    attributes = permitted_params.slice(*UPSERT_ATTRIBUTES.map(&:to_s)).compact
    if attributes.present?
      @card.update!(attributes)
      ::Crm::ActivityLogger.new(card: @card, actor: Current.user, event_type: 'update', payload: attributes).perform
      broadcast_card(::Events::Types::CRM_CARD_UPDATED)
    end
    render :show, status: :ok
  end

  # The 'ai' metadata block is server-owned (value_source lock, summary, eval
  # timestamps). Clients must never write it — strip it from incoming metadata
  # while preserving the existing server-side ai block.
  def strip_ai_metadata!(attributes)
    return unless attributes.key?(:metadata) && attributes[:metadata].is_a?(Hash)

    incoming = attributes[:metadata].except('ai')
    server_ai = (@card.metadata || {})['ai']
    incoming['ai'] = server_ai if server_ai.present?
    attributes[:metadata] = incoming
  end

  # A manual value edit locks the field: the AI auto-fill must not undo a human
  # correction on a later evaluation (Crm::Ai::Evaluator#apply_ai_value!).
  def mark_value_source_human!(attributes)
    metadata = (attributes[:metadata].presence || @card.metadata || {}).deep_dup
    metadata['ai'] = (metadata['ai'] || {}).merge('value_source' => 'human')
    attributes[:metadata] = metadata
  end

  def stage_badge_payload(card)
    return if card.blank? || card.stage.blank?

    {
      pipeline_name: card.pipeline&.name,
      stage_name: card.stage.name,
      stage_color: card.stage.color,
      multiple_pipelines: Current.account.crm_pipelines.count > 1
    }
  end

  def ai_suggestion_payload(suggestion)
    return if suggestion.blank?

    {
      id: suggestion.id,
      from_stage_id: suggestion.from_stage_id,
      to_stage_id: suggestion.to_stage_id,
      to_stage_name: suggestion.to_stage&.name,
      confidence: suggestion.confidence.to_f,
      reasoning: suggestion.reasoning,
      status: suggestion.status,
      created_at: suggestion.created_at
    }
  end

  def fetch_card
    @card = policy_scope(::Crm::Card).includes(:contact, :owner, :inbox, :stage, :pipeline, :primary_conversation).find(params[:id])
    authorize @card, "#{action_name}?".to_sym
  end

  def conversation_for_from_conversation!
    return Current.account.conversations.find_by!(display_id: params[:conversation_display_id]) if params[:conversation_display_id].present?

    Current.account.conversations.find(params[:conversation_id])
  end

  def broadcast_card(event_name)
    ::Crm::Cards::Broadcaster.broadcast(@card, event_name)
  end

  def filtered_cards
    ::Crm::Cards::FilterQuery.new(scope: policy_scope(::Crm::Card), params: params).perform
  end

  def per_page
    params.fetch(:per_page, RESULTS_PER_PAGE).to_i.clamp(1, MAX_RESULTS_PER_PAGE)
  end

  def from_conversation_handler(conversation)
    ::Crm::Cards::FromConversationHandler.new(
      account: Current.account,
      user: Current.user,
      conversation: conversation,
      requested_params: create_params.to_h.with_indifferent_access
    )
  end

  def conversation_from_params(permitted_params)
    return if permitted_params[:conversation_id].blank?

    conversation = Current.account.conversations.find(permitted_params[:conversation_id])
    authorize_crm_conversation!(conversation)
    conversation
  end

  def crm_visibility
    @crm_visibility ||= ::Crm::Conversations::Visibility.new(
      account: Current.account,
      user: Current.user,
      account_user: Current.account_user
    )
  end

  def authorize_crm_conversation!(conversation)
    authorize conversation, :show?
    ::Crm::Conversations::AccessAuthorizer.new(
      account: Current.account,
      user: Current.user,
      account_user: Current.account_user
    ).authorize!(conversation)
  end

  def create_authorizer
    ::Crm::Cards::CreateAuthorizer.new(account: Current.account, user: Current.user, account_user: Current.account_user)
  end

  def resolved_create_params(permitted_params, conversation:)
    ::Crm::Cards::CreateParamsResolver.new(
      account: Current.account,
      user_context: pundit_user,
      params: permitted_params,
      conversation: conversation
    ).perform
  end

  def create_params
    parameter_set(:card).permit(
      :pipeline_id, :stage_id, :contact_id, :conversation_id, :inbox_id, :owner_id, :team_id,
      :title, :description, :value_cents, :currency, :status, :lost_reason, :source,
      :priority, :score, :expected_close_at, :external_id, metadata: {}
    )
  end

  # `status` and `stage_id` are intentionally NOT permitted on update: won/lost
  # transitions must go through #close (audited + value lock) and stage changes
  # through #move, never a raw PATCH (which would bypass the activity log,
  # closed_at, and stage-move side effects). `owner_id` IS permitted so the list
  # view can inline-assign / reassign an owner (authorized via card :update? +
  # same-account validation on the model).
  def update_params
    parameter_set(:card).permit(
      :title, :description, :value_cents, :currency, :lost_reason, :source,
      :priority, :score, :expected_close_at, :external_id, :owner_id, metadata: {}
    )
  end
end
