class Captain::ConversationOutcomeTracker
  include Captain::ConversationOutcomeAttribution

  pattr_initialize [:conversation!, :assistant]

  STREAM_LOCK_NAMESPACE = 894_512_337

  # --- Boundaries -----------------------------------------------------------

  def record_eligibility(at:)
    safely_track(:eligibility) do
      next unless account.feature_enabled?('captain_integration_v2')

      initial = episodes.trigger_initial.take
      initial ? lower_initial_anchor(initial, at) : create_initial_episode(at)
    end
  end

  # Runs inside Captain::ConversationOutcomeBoundaryJob. Unlike facts, a lost
  # boundary strands every later fact in the wrong episode, so this write must
  # raise on failure and let the job retry instead of failing open.
  def record_reopen(at:)
    return if episodes.none?

    with_stream_lock do
      next if episodes.exists?(started_at: at)

      insert_boundary(at)
    end
  end

  # --- Facts ----------------------------------------------------------------

  def record_captain_reply(message:)
    return unless public_captain_reply?(message)

    track_fact(:captain_reply, at: message.created_at) do |episode|
      episode.with_lock do
        recount_captain_replies(episode)
        episode.save!
      end
    end
  end

  def record_handoff(at:, reason_category:)
    track_fact(:handoff, at: at) do |episode|
      episode.with_lock do
        # First handoff wins within the episode: re-delivered or later handoff
        # events must not overwrite the reason the episode left Captain.
        next episode if episode.handoff_at.present? && episode.handoff_at <= at

        episode.handoff_at = at
        episode.handoff_reason_category = reason_category
        episode.save!
      end
    end
  end

  def record_human_reply(message:)
    return unless public_human_reply?(message)

    track_fact(:human_reply, at: message.created_at) do |episode|
      episode.with_lock do
        episode.first_human_reply_at = earliest(episode.first_human_reply_at, message.created_at)
        episode.save! if episode.changed?
      end
    end
  end

  def record_resolution(at:)
    track_fact(:resolution, at: at) do |episode|
      episode.with_lock do
        # Latest resolution wins within the episode; out-of-order events must
        # not roll it back.
        next episode if episode.resolved_at.present? && at < episode.resolved_at

        episode.resolved_at = at
        episode.save!
      end
    end
  end

  def record_csat(response:)
    # The response is attributed through the survey message that solicited it,
    # so a late submission lands on the episode that sent the survey, not on
    # whichever episode is open when the customer answers.
    survey_at = response.message&.created_at
    return if survey_at.blank?

    track_fact(:csat, at: survey_at) do |episode|
      episode.with_lock do
        episode.update!(csat_rating: response.rating, csat_received_at: response.created_at)
      end
    end
  end

  private

  def account
    conversation.account
  end

  def episodes
    ConversationOutcome.where(account_id: conversation.account_id, conversation_id: conversation.id)
  end

  # --- Initial episode ------------------------------------------------------

  def lower_initial_anchor(initial, at)
    return initial unless at < initial.started_at

    # The initial anchor is demand-time and mutable (earliest wins). Boundary
    # anchors are immutable identities and are never lowered.
    initial.with_lock do
      initial.update!(started_at: earliest(initial.started_at, at)) if at < initial.started_at
    end
    initial
  end

  def create_initial_episode(at)
    earliest_boundary = episodes.chronological.first
    # An initial episode must precede every boundary. When the stream already
    # has a boundary episode and this demand falls inside its window, the
    # true initial start is still unknown; wait for an earlier eligible event.
    return if earliest_boundary && at >= earliest_boundary.started_at

    ConversationOutcome.create!(
      account: account,
      assistant: assistant,
      conversation: conversation,
      inbox: conversation.inbox,
      episode_trigger: 'initial',
      started_at: at,
      ended_at: earliest_boundary&.started_at
    )
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
    episodes.trigger_initial.take || raise
  end

  # --- Boundary insertion ---------------------------------------------------

  def insert_boundary(at)
    predecessor = episodes.where(started_at: ...at).chronological.last
    successor = episodes.where('started_at > ?', at).chronological.first

    # The predecessor closes before the insert: the open-episode partial
    # unique index permits only one open row, and partial indexes are not
    # deferrable. The surrounding transaction rolls the close back if the
    # insert fails.
    predecessor&.update!(ended_at: at)
    episode = ConversationOutcome.create!(
      account: account,
      assistant: boundary_assistant,
      conversation: conversation,
      inbox: conversation.inbox,
      episode_trigger: 'reopen',
      started_at: at,
      ended_at: successor&.started_at
    )
    repair_attribution(predecessor, episode)
  end

  def boundary_assistant
    conversation.inbox.captain_assistant || episodes.chronological.last&.assistant
  end

  def with_stream_lock(&)
    ApplicationRecord.transaction do
      ApplicationRecord.connection.select_value(
        "SELECT pg_advisory_xact_lock(#{STREAM_LOCK_NAMESPACE}, #{conversation.id.to_i % (2**31)})"
      )
      yield
    end
  end

  # --- Fact attribution -----------------------------------------------------

  def track_fact(action, at:)
    safely_track(action) do
      episode = attributed_episode(at)
      next unless episode

      yield episode
      episode
    end
  end

  def attributed_episode(at)
    # Clamp rule: a fact timestamped before the stream's first episode
    # attributes to that first episode.
    episodes.covering(at).chronological.last || episodes.chronological.first
  end

  # Fact tracking is reporting, not product behavior: a tracking bug must
  # never break message delivery or conversation state transitions. Boundary
  # writes (record_reopen) are deliberately not routed through this.
  def safely_track(action)
    yield
  rescue StandardError => e
    report_tracking_failure(action, e)
    nil
  end

  # Reporting the failure must itself fail open: the account read can hit the
  # database again during the same outage that broke tracking, and a secondary
  # error here would otherwise escape into the customer action.
  def report_tracking_failure(action, error)
    ChatwootExceptionTracker.new(error, account: account).capture_exception
    Rails.logger.error(
      "[CAPTAIN][ConversationOutcomeTracker] Failed to record #{action} for conversation=#{conversation.display_id}: #{error.message}"
    )
  rescue StandardError
    nil
  end
end
