class Crm::Conversations::CardSyncer
  AUTO_SYNC_METADATA = 'crm_auto_sync'.freeze
  OBSERVER_SOURCE = 'conversation_observer'.freeze

  def initialize(conversation:, message: nil)
    @conversation = conversation
    @message = message
    @account = conversation&.account
    @dedup_match_reason = nil
    @dedup_window_days = nil
  end

  def perform
    return unless Crm::Config.enabled?
    return unless load_conversation
    return if @conversation.inbox_id.blank?

    pipeline_inbox = auto_create_pipeline_inbox
    return if pipeline_inbox.blank?

    sync_card(pipeline_inbox)
  end

  private

  def load_conversation
    @conversation = Conversation.find_by(id: @conversation&.id)
    @account = @conversation&.account
    @conversation.present? && @account.present?
  end

  def sync_card(pipeline_inbox)
    card = nil
    event_name = nil

    Crm::Conversations::SyncLock.new(account: @account, conversation: @conversation).perform do
      card = existing_card(pipeline_inbox)
      if card.present?
        event_name = refresh_card(card) ? Events::Types::CRM_CARD_UPDATED : nil
        log_dedup_reuse(card)
      else
        card = create_card(pipeline_inbox)
        event_name = Events::Types::CRM_CARD_CREATED if card.present?
      end
    end

    Crm::Cards::Broadcaster.broadcast(card, event_name) if card.present? && event_name.present?
    maybe_stop_ai_followup(card) if card.present?
    schedule_ai_evaluation(card) if card.present?
    card
  end

  # Auto-stop the AI follow-up cadence when the contact replies. Guarded internally
  # (acts only on an inbound message with an active ai_followup cadence); never
  # touches manual follow-ups or the sync/AI-evaluation flow above.
  def maybe_stop_ai_followup(card)
    Crm::FollowUps::AutoFollowupCanceler.new(card: card, message: @message).maybe_cancel
  end

  def schedule_ai_evaluation(card)
    Crm::Ai::EnrichCardMediaJob.perform_later(card.id) if Crm::Ai::Config.media_enabled?
    Crm::Ai::Observer.new(card: card).schedule_evaluation
  end

  def auto_create_pipeline_inbox
    setting = @account.crm_inbox_settings.find_by(inbox_id: @conversation.inbox_id)
    return if inbox_auto_create_disabled?(setting)

    scope = @account.crm_pipeline_inboxes
                    .includes(:pipeline, :default_stage)
                    .joins(:pipeline)
                    .where(inbox_id: @conversation.inbox_id, auto_create_card: true)
                    .merge(Crm::Pipeline.active)
                    .order('crm_pipelines.position ASC, crm_pipeline_inboxes.id ASC')

    preferred_pipeline_inbox(scope, setting) || scope.first
  end

  def inbox_auto_create_disabled?(setting)
    setting.present? && (!setting.crm_enabled? || !setting.auto_create_card?)
  end

  def preferred_pipeline_inbox(scope, setting)
    return if setting&.default_pipeline_id.blank?

    scope.find_by(pipeline_id: setting.default_pipeline_id)
  end

  def existing_card(pipeline_inbox)
    @dedup_match_reason = nil
    result = Crm::Conversations::AutoCreateDeduplicator.new(
      account: @account,
      conversation: @conversation,
      pipeline_inbox: pipeline_inbox
    ).perform(@account.crm_cards.open)
    @dedup_match_reason = result.reason
    @dedup_window_days = result.window_days
    result.card
  end

  def create_card(pipeline_inbox)
    stage = default_stage_for(pipeline_inbox)
    return if stage.blank?

    Crm::Cards::Creator.new(
      account: @account,
      user: nil,
      conversation: @conversation,
      params: {
        pipeline_id: pipeline_inbox.pipeline_id,
        stage_id: stage.id,
        metadata: auto_sync_metadata
      }
    ).perform
  end

  def refresh_card(card)
    attributes = refresh_attributes(card)
    return false if attributes.blank?

    card.update!(attributes)
    ensure_conversation_link(card)
    log_refresh(card, attributes)
    true
  end

  def refresh_attributes(card)
    attributes = {
      contact_id: @conversation.contact_id,
      inbox_id: @conversation.inbox_id,
      source: @conversation.inbox&.channel_type,
      metadata: refreshed_metadata(card)
    }.compact

    merge_activity_attributes(attributes)
    attributes[:conversation_id] = @conversation.id if card.conversation_id.blank?
    attributes[:owner_id] = @conversation.assignee_id if sync_assignment?(card)
    attributes[:team_id] = @conversation.team_id if sync_team?(card)
    attributes.reject { |key, value| values_equal?(card.public_send(key), value) }
  end

  # Assignment/team syncs arrive without @message; they must not move the card's
  # activity clock — stage moves and linkers legitimately set last_activity_at to
  # Time.current, and a stale real-message date would regress it.
  def merge_activity_attributes(attributes)
    return if @message.blank?

    real_message_at = last_message_at
    return if real_message_at.blank?

    attributes[:last_message_at] = real_message_at
    attributes[:last_activity_at] = real_message_at
  end

  # Auto-synced cards mirror the conversation assignee exactly (set on assign,
  # clear on unassign) so owner stays a clean human field and reflects realtime.
  # Manually-owned cards are only filled when blank and never auto-cleared.
  def sync_assignment?(card)
    return true if auto_synced_card?(card)

    @conversation.assignee_id.present? && card.owner_id.blank?
  end

  def sync_team?(card)
    @conversation.team_id.present? && (auto_synced_card?(card) || card.team_id.blank?)
  end

  def values_equal?(current_value, next_value)
    current_value == next_value
  end

  def default_stage_for(pipeline_inbox)
    pipeline_inbox.default_stage || pipeline_inbox.pipeline.stages.order(:position, :id).first
  end

  def last_message_at
    Crm::Conversations::LastRealMessageAt.for(@conversation)
  end

  def auto_sync_metadata
    {
      AUTO_SYNC_METADATA => {
        'source' => OBSERVER_SOURCE,
        'message_id' => @message&.id,
        'synced_at' => Time.current.iso8601
      }
    }
  end

  def refreshed_metadata(card)
    (card.metadata || {}).deep_merge(auto_sync_metadata).deep_merge(
      'source_conversation' => {
        'display_id' => @conversation.display_id,
        'status' => @conversation.status,
        'inbox_id' => @conversation.inbox_id,
        'assignee_id' => @conversation.assignee_id,
        'team_id' => @conversation.team_id
      }
    )
  end

  def auto_synced_card?(card)
    card.metadata.to_h.dig(AUTO_SYNC_METADATA, 'source') == OBSERVER_SOURCE
  end

  def log_refresh(card, attributes)
    audited_attributes = attributes.except(:last_message_at, :last_activity_at, :metadata)
    return if audited_attributes.blank?

    Crm::ActivityLogger.new(
      card: card,
      actor: nil,
      event_type: 'conversation_sync',
      conversation: @conversation,
      payload: audited_attributes
    ).perform
  end

  def log_dedup_reuse(card)
    return if @dedup_match_reason.blank?

    Crm::Conversations::DedupReuseLogger.new(
      card: card,
      conversation: @conversation,
      reason: @dedup_match_reason,
      window_days: @dedup_window_days
    ).perform
  end

  def ensure_conversation_link(card)
    Crm::CardConversation.find_or_create_by!(
      account: @account,
      card: card,
      conversation: @conversation
    ) do |link|
      link.is_primary = card.conversation_id == @conversation.id
    end
  end
end
