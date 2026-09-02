class Captain::ConversationOutcomeBackfillService # rubocop:disable Metrics/ClassLength
  DEFAULT_ACTIVITY_WINDOW = 60.days

  RESOLUTION_EVENT_NAMES = %w[
    conversation_resolved
    conversation_captain_inference_resolved
  ].freeze
  HANDOFF_EVENT_NAMES = %w[
    conversation_bot_handoff
    conversation_captain_inference_handoff
  ].freeze
  RELEVANT_EVENT_NAMES = (RESOLUTION_EVENT_NAMES + HANDOFF_EVENT_NAMES + ['conversation_opened']).freeze

  Result = Data.define(:conversation_id, :status, :episode_count, :reason, :error)
  Timeline = Data.define(
    :assistant_messages,
    :trigger_messages,
    :public_messages,
    :sessions,
    :events,
    :csat_responses
  )

  class << self
    def candidate_scope(assistant, cutoff: DEFAULT_ACTIVITY_WINDOW.ago)
      base_scope = assistant.account.conversations.where(last_activity_at: cutoff..)
      message_conversations = base_scope.where(id: assistant.messages.select(:conversation_id))
      session_conversation_ids = assistant.agent_sessions
                                          .where(subject_type: 'Conversation')
                                          .select(:subject_id)
      session_conversations = base_scope.where(id: session_conversation_ids)
      existing_conversation_ids = assistant.account.conversation_outcomes.select(:conversation_id)

      message_conversations.or(session_conversations).where.not(id: existing_conversation_ids)
    end
  end

  def initialize(assistant:, conversation_ids:)
    @assistant = assistant
    @conversation_ids = conversation_ids
  end

  def perform
    load_batch
    conversations.map { |conversation| backfill(conversation, timeline_for(conversation.id)) }
  end

  private

  attr_reader :assistant, :conversation_ids, :conversations, :existing_conversation_ids

  def load_batch
    @conversations = assistant.account.conversations.where(id: conversation_ids).order(:id).to_a
    ids = conversations.map(&:id)
    @existing_conversation_ids = existing_outcome_ids(ids)
    @assistant_messages = grouped_assistant_messages(ids)
    @trigger_messages = grouped_trigger_messages(ids)
    @public_messages = grouped_public_messages(ids)
    @sessions = grouped_sessions(ids)
    @events = grouped_events(ids)
    @csat_responses = grouped_csat_responses(ids)
  end

  def existing_outcome_ids(ids)
    ConversationOutcome.where(account_id: assistant.account_id, conversation_id: ids).distinct.pluck(:conversation_id).to_set
  end

  def grouped_assistant_messages(ids)
    Message.where(account_id: assistant.account_id, conversation_id: ids, sender_type: 'Captain::Assistant')
           .order(:created_at, :id)
           .group_by(&:conversation_id)
  end

  def grouped_trigger_messages(ids)
    Message.captain_response_triggering
           .where(messages: { account_id: assistant.account_id, conversation_id: ids })
           .order(:created_at, :id)
           .group_by(&:conversation_id)
  end

  def grouped_public_messages(ids)
    Message.where(
      account_id: assistant.account_id,
      conversation_id: ids,
      message_type: Message.message_types[:outgoing],
      private: false
    ).order(:created_at, :id).group_by(&:conversation_id)
  end

  def grouped_sessions(ids)
    Captain::AgentSession.where(
      account_id: assistant.account_id,
      subject_type: 'Conversation',
      subject_id: ids
    ).order(:created_at, :id).group_by(&:subject_id)
  end

  def grouped_events(ids)
    ReportingEvent.where(
      account_id: assistant.account_id,
      conversation_id: ids,
      name: RELEVANT_EVENT_NAMES
    ).order(:created_at, :id).group_by(&:conversation_id)
  end

  def grouped_csat_responses(ids)
    CsatSurveyResponse.where(account_id: assistant.account_id, conversation_id: ids)
                      .includes(:message)
                      .order(:created_at, :id)
                      .group_by(&:conversation_id)
  end

  def timeline_for(conversation_id)
    Timeline.new(
      assistant_messages: @assistant_messages.fetch(conversation_id, []),
      trigger_messages: @trigger_messages.fetch(conversation_id, []),
      public_messages: @public_messages.fetch(conversation_id, []),
      sessions: @sessions.fetch(conversation_id, []),
      events: @events.fetch(conversation_id, []),
      csat_responses: @csat_responses.fetch(conversation_id, [])
    )
  end

  def backfill(conversation, timeline)
    return skipped(conversation, :already_backfilled) if existing_conversation_ids.include?(conversation.id)

    participant_ids = participant_assistant_ids(timeline)
    return skipped(conversation, :no_assistant_activity) if participant_ids.empty?
    return skipped(conversation, :multiple_assistants) if participant_ids != [assistant.id]

    initial_trigger = initial_trigger(timeline)
    return skipped(conversation, :missing_initial_demand) unless initial_trigger

    attributes = build_outcomes(conversation, timeline, initial_trigger.created_at)
    persist(conversation, attributes)
  rescue ActiveRecord::RecordNotUnique
    skipped(conversation, :concurrently_backfilled)
  rescue StandardError => e
    Result.new(conversation_id: conversation.id, status: :failed, episode_count: 0, reason: nil, error: e)
  end

  def participant_assistant_ids(timeline)
    message_ids = timeline.assistant_messages.map(&:sender_id)
    session_ids = timeline.sessions.map(&:assistant_id)

    (message_ids + session_ids).compact.uniq.sort
  end

  def initial_trigger(timeline)
    first_activity_at = (
      timeline.assistant_messages.map(&:created_at) + timeline.sessions.map(&:created_at)
    ).min
    return unless first_activity_at

    timeline.trigger_messages.find { |message| message.created_at <= first_activity_at }
  end

  def build_outcomes(conversation, timeline, initial_started_at)
    boundaries = episode_boundaries(timeline.events, initial_started_at)

    boundaries.each_with_index.map do |boundary, index|
      ends_at = boundaries[index + 1]&.fetch(:started_at)
      outcome_attributes(conversation, timeline, boundary, ends_at)
    end
  end

  def episode_boundaries(events, initial_started_at)
    resolved = false
    reopens = ordered_events(events).filter_map do |event|
      time = event_time(event)
      next if time < initial_started_at

      resolved = true if RESOLUTION_EVENT_NAMES.include?(event.name)
      next unless reopen_event?(event, resolved, time, initial_started_at)

      resolved = false
      time
    end

    [{ episode_trigger: 'initial', started_at: initial_started_at }] +
      reopens.uniq.map { |time| { episode_trigger: 'reopen', started_at: time } }
  end

  def reopen_event?(event, resolved, time, initial_started_at)
    event.name == 'conversation_opened' && resolved && time > initial_started_at
  end

  def outcome_attributes(conversation, timeline, boundary, ends_at)
    starts_at = boundary[:started_at]
    resolved_at = terminal_event_at(timeline.events, RESOLUTION_EVENT_NAMES, starts_at, ends_at)
    handoff_at = handoff_at(timeline, starts_at, ends_at)
    snapshot_at = [resolved_at, handoff_at].compact.max
    captain_replies = captain_replies(timeline, starts_at, ends_at, snapshot_at)
    csat_response = csat_response(timeline, starts_at, ends_at)

    base_outcome_attributes(conversation, boundary, ends_at).merge(
      episode_facts(timeline, starts_at, ends_at, resolved_at, handoff_at, captain_replies, csat_response)
    )
  end

  def base_outcome_attributes(conversation, boundary, ends_at)
    {
      account_id: conversation.account_id,
      assistant_id: assistant.id,
      conversation_id: conversation.id,
      inbox_id: conversation.inbox_id,
      episode_trigger: boundary[:episode_trigger],
      started_at: boundary[:started_at],
      ended_at: ends_at
    }
  end

  def episode_facts(timeline, starts_at, ends_at, resolved_at, handoff_at, captain_replies, csat_response) # rubocop:disable Metrics/ParameterLists
    {
      captain_reply_count: captain_replies.size,
      first_captain_reply_at: captain_replies.first&.created_at,
      last_captain_reply_at: captain_replies.last&.created_at,
      first_human_reply_at: first_human_reply_at(timeline, starts_at, ends_at),
      handoff_at: handoff_at,
      handoff_reason_category: nil,
      resolved_at: resolved_at,
      csat_rating: csat_response&.rating,
      csat_received_at: csat_response&.created_at
    }
  end

  def captain_replies(timeline, starts_at, ends_at, snapshot_at)
    return [] unless snapshot_at

    timeline.assistant_messages.select do |message|
      message.sender_id == assistant.id && message.outgoing? && !message.private? &&
        within_episode?(message.created_at, starts_at, ends_at) && message.created_at <= snapshot_at
    end
  end

  def first_human_reply_at(timeline, starts_at, ends_at)
    timeline.public_messages.find do |message|
      human_reply?(message) && within_episode?(message.created_at, starts_at, ends_at)
    end&.created_at
  end

  def human_reply?(message)
    return false if message.content_attributes['automation_rule_id'].present?
    return false if message.additional_attributes['campaign_id'].present?

    message.sender_type == 'User' || message.content_attributes['external_echo'].present?
  end

  def handoff_at(timeline, starts_at, ends_at)
    timeline.events.filter_map do |event|
      next unless HANDOFF_EVENT_NAMES.include?(event.name)

      time = event_time(event)
      next unless within_episode?(time, starts_at, ends_at)
      next unless assistant_activity_before?(timeline, starts_at, time)

      time
    end.max
  end

  def assistant_activity_before?(timeline, starts_at, handoff_at)
    timeline.assistant_messages.any? do |message|
      message.sender_id == assistant.id && message.created_at.between?(starts_at, handoff_at)
    end || timeline.sessions.any? do |session|
      session.assistant_id == assistant.id && session.created_at.between?(starts_at, handoff_at)
    end
  end

  def terminal_event_at(events, event_names, starts_at, ends_at)
    events.filter_map do |event|
      next unless event_names.include?(event.name)

      time = event_time(event)
      time if within_episode?(time, starts_at, ends_at)
    end.max
  end

  def csat_response(timeline, starts_at, ends_at)
    timeline.csat_responses.select do |response|
      within_episode?(response.message.created_at, starts_at, ends_at)
    end.max_by(&:created_at)
  end

  def ordered_events(events)
    events.sort_by { |event| [event_time(event), event.id] }
  end

  def event_time(event)
    event.event_end_time || event.created_at
  end

  def within_episode?(time, starts_at, ends_at)
    time >= starts_at && (ends_at.nil? || time < ends_at)
  end

  def persist(conversation, attributes)
    created = false

    ApplicationRecord.transaction do
      conversation.lock!
      next if ConversationOutcome.exists?(account_id: conversation.account_id, conversation_id: conversation.id)

      ConversationOutcome.create!(attributes)
      created = true
    end

    return skipped(conversation, :concurrently_backfilled) unless created

    Result.new(
      conversation_id: conversation.id,
      status: :created,
      episode_count: attributes.size,
      reason: nil,
      error: nil
    )
  end

  def skipped(conversation, reason)
    Result.new(conversation_id: conversation.id, status: :skipped, episode_count: 0, reason: reason, error: nil)
  end
end
