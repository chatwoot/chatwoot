class Crm::ConversationObserverListener < BaseListener
  def message_created(event)
    return unless Crm::Config.enabled?

    message = event.data[:message]
    return if ignored_message?(message)

    Crm::SyncConversationCardJob.perform_later(message.conversation_id, message.id)
  end

  # SLA auto-apply v1 (gatilho "conversa criada"): hand off to a job so listener
  # stays fast; all gating (feature flag, policy match, groups) lives in the job.
  def conversation_created(event)
    return unless Crm::Config.enabled?

    conversation, = extract_conversation_and_account(event)
    return if conversation&.id.blank?

    Crm::SlaAutoApplyJob.perform_later(conversation.id)
  end

  # Keep the card's real-time "responsible" in sync when the conversation is
  # (un)assigned: re-sync the card (mirrors owner, re-broadcasts to the board).
  def assignee_changed(event)
    return unless Crm::Config.enabled?

    conversation, = extract_conversation_and_account(event)
    return if conversation&.id.blank?

    Crm::SyncConversationCardJob.perform_later(conversation.id)
    enqueue_handoff_pickup(conversation, event)
  end

  # Keep the card's team in sync on a team-only reassignment (e.g. an Autonomia
  # native-agent handoff with strategy 'assign_team', which updates team without
  # touching the assignee). Without this, a team change never enqueues a card
  # sync and the card's team_id lags. Mirrors assignee_changed; same idempotent
  # job; purely additive (assignee/message paths unchanged).
  def team_changed(event)
    return unless Crm::Config.enabled?

    conversation, = extract_conversation_and_account(event)
    return if conversation&.id.blank?

    Crm::SyncConversationCardJob.perform_later(conversation.id)
  end

  # Labels live on the conversation, not the card, so a label change never triggers
  # a card upsert: re-broadcast the linked cards instead so the board pill/filters
  # stay consistent in realtime. changed_attributes carries previous_changes, whose
  # keys are strings ('label_list' is in Conversation#list_of_keys).
  def conversation_updated(event)
    return unless Crm::Config.enabled?

    conversation, = extract_conversation_and_account(event)
    return if conversation&.id.blank?
    return unless event.data[:changed_attributes]&.key?('label_list')

    Crm::Cards::RebroadcastConversationCardsJob.perform_later(conversation.id)
  end

  private

  # Telemetria de pega do convite R3 (só quando IA está ligada; o job é no-op
  # barato se não houver convite pendente). Passa snapshot do evento (assignee +
  # hora) para não medir o atraso da fila nem creditar reatribuição posterior.
  def enqueue_handoff_pickup(conversation, event)
    return unless Crm::Ai::Config.enabled?

    Crm::Ai::HandoffPickupJob.perform_later(conversation.id, conversation.assignee_id, event.timestamp.iso8601)
  end

  def ignored_message?(message)
    message.blank? ||
      message.conversation_id.blank? ||
      message.activity? ||
      message.private?
  end
end
