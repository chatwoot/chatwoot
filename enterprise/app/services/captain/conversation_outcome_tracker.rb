class Captain::ConversationOutcomeTracker
  pattr_initialize [:conversation!, :assistant]

  def record_eligibility(at:)
    safely_track(:eligibility, at: at) do
      next unless account.feature_enabled?('captain_integration_v2')

      initial = episodes.trigger_initial.take
      initial ? lower_initial_anchor(initial, at) : create_initial_episode(at)
    end
  end

  def record_reopen(at:)
    safely_track(:reopen, at: at) do
      next if episodes.none?

      ApplicationRecord.transaction do
        next if episodes.exists?(started_at: at)

        predecessor = episodes.find_by!(ended_at: nil)
        predecessor.update!(ended_at: at)
        ConversationOutcome.create!(
          account: account,
          assistant: conversation.inbox.captain_assistant || predecessor.assistant,
          conversation: conversation,
          inbox: conversation.inbox,
          episode_trigger: 'reopen',
          started_at: at
        )
      end
    end
  end

  def record_handoff(at:, reason_category:)
    snapshot_episode(:handoff, at: at) do |episode|
      next false if episode.handoff_at.present? && episode.handoff_at <= at

      episode.handoff_at = at
      episode.handoff_reason_category = reason_category
      true
    end
  end

  def record_resolution(at:)
    snapshot_episode(:resolution, at: at) do |episode|
      next false if episode.resolved_at.present? && at < episode.resolved_at

      episode.resolved_at = at
      true
    end
  end

  def record_csat(response:)
    safely_track(:csat, at: response.message.created_at) do
      episode = attributed_episode(response.message.created_at)
      next unless episode

      episode.update!(csat_rating: response.rating, csat_received_at: response.created_at)
      episode
    end
  end

  private

  def account
    conversation.account
  end

  def episodes
    ConversationOutcome.where(account_id: conversation.account_id, conversation_id: conversation.id)
  end

  def lower_initial_anchor(initial, at)
    return initial unless at < initial.started_at

    initial.with_lock do
      initial.update!(started_at: at) if at < initial.started_at
    end
    initial
  end

  def create_initial_episode(at)
    ConversationOutcome.create!(
      account: account,
      assistant: assistant,
      conversation: conversation,
      inbox: conversation.inbox,
      episode_trigger: 'initial',
      started_at: at
    )
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
    initial = episodes.trigger_initial.take || raise
    lower_initial_anchor(initial, at)
  end

  def snapshot_episode(action, at:)
    safely_track(action, at: at) do
      episode = attributed_episode(at)
      next unless episode
      next episode unless yield episode

      snapshot_message_facts(episode, through: at)
      episode.save! if episode.changed?
      episode
    end
  end

  def attributed_episode(at)
    episodes.covering(at).chronological.last || episodes.chronological.first
  end

  def snapshot_message_facts(episode, through:)
    messages = conversation.messages.where(created_at: episode.started_at..through)
    replies = messages.where(sender_type: 'Captain::Assistant', message_type: :outgoing, private: false)

    episode.captain_reply_count = replies.count
    episode.first_captain_reply_at = replies.minimum(:created_at)
    episode.last_captain_reply_at = replies.maximum(:created_at)
    episode.first_human_reply_at = messages.where(message_type: :outgoing, private: false)
                                           .order(:created_at)
                                           .detect { |message| public_human_reply?(message) }
                                           &.created_at
  end

  def public_human_reply?(message)
    return false if message.content_attributes['automation_rule_id'].present?
    return false if message.additional_attributes['campaign_id'].present?

    message.sender.is_a?(User) || message.content_attributes['external_echo'].present?
  end

  def safely_track(action, at:)
    yield
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: account).capture_exception
    Rails.logger.error(
      "[CAPTAIN][ConversationOutcomeTracker] Failed to record #{action} for conversation=#{conversation.display_id} " \
      "at=#{at.iso8601(6)}: #{e.message}"
    )
    nil
  end
end
