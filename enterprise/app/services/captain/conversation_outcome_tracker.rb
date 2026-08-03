class Captain::ConversationOutcomeTracker
  pattr_initialize [:conversation!, :assistant!]

  def record_eligibility(at:)
    safely_track(:eligibility) do
      next unless account.feature_enabled?('captain_integration_v2')

      find_or_create_outcome(at)
    end
  end

  def record_captain_reply(message:)
    return unless public_captain_reply?(message)

    track_existing_outcome(:captain_reply) do |outcome|
      outcome.with_lock do
        outcome.first_captain_reply_at = earliest(outcome.first_captain_reply_at, message.created_at)
        outcome.last_captain_reply_at = latest(outcome.last_captain_reply_at, message.created_at)
        outcome.captain_reply_count = public_captain_replies.count
        outcome.save!
      end
    end
  end

  def record_handoff(at:, reason_category:)
    track_existing_outcome(:handoff) do |outcome|
      outcome.with_lock do
        # First handoff wins: re-delivered or later handoff events must not
        # overwrite the reason the conversation originally left Captain.
        next outcome if outcome.handoff_at.present? && outcome.handoff_at <= at

        outcome.handoff_at = at
        outcome.handoff_reason_category = reason_category
        outcome.save!
      end
    end
  end

  def record_human_reply(message:)
    return unless public_human_reply?(message)

    track_existing_outcome(:human_reply) do |outcome|
      outcome.with_lock do
        outcome.first_human_reply_at = earliest(outcome.first_human_reply_at, message.created_at)
        outcome.save! if outcome.changed?
      end
    end
  end

  def record_resolution(at:)
    track_existing_outcome(:resolution) do |outcome|
      outcome.with_lock do
        # Latest resolution wins: after a reopen the final resolution is the one
        # that counts, and out-of-order events must not roll it back.
        next outcome if outcome.resolved_at.present? && at < outcome.resolved_at

        outcome.resolved_at = at
        outcome.save!
      end
    end
  end

  def record_reopen(at:)
    track_existing_outcome(:reopen) do |outcome|
      outcome.with_lock do
        # The caller classifies the reopen from the status transition, so no
        # resolved_at check here: it would drop legitimate reopens whenever the
        # resolution event is delivered late. Re-delivered events must not
        # double count, hence the last_reopened_at guard.
        next outcome if outcome.last_reopened_at.present? && at <= outcome.last_reopened_at

        outcome.last_reopened_at = at
        outcome.reopen_count += 1
        outcome.save!
      end
    end
  end

  def record_csat(response:)
    track_existing_outcome(:csat) do |outcome|
      outcome.with_lock do
        outcome.update!(csat_rating: response.rating, csat_received_at: response.created_at)
      end
    end
  end

  private

  def account
    conversation.account
  end

  def conversation_outcome
    ConversationOutcome.find_by(
      account: account,
      assistant: assistant,
      conversation: conversation
    )
  end

  def find_or_create_outcome(at)
    # created_at is the demand-start anchor for reporting windows, so it must
    # reflect the eligible message's time, not row insertion time — channels
    # like TikTok backdate message timestamps to the provider's clock.
    conversation_outcome || ConversationOutcome.create!(
      account: account,
      assistant: assistant,
      conversation: conversation,
      inbox: conversation.inbox,
      created_at: at
    )
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
    conversation_outcome || raise
  end

  def public_captain_reply?(message)
    message.conversation_id == conversation.id &&
      message.sender == assistant &&
      message.outgoing? &&
      !message.private?
  end

  def public_human_reply?(message)
    return false unless message.conversation_id == conversation.id && message.outgoing? && !message.private?
    return false if message.content_attributes['automation_rule_id'].present?
    return false if message.additional_attributes['campaign_id'].present?

    message.sender.is_a?(User) || message.content_attributes['external_echo'].present?
  end

  def public_captain_replies
    conversation.messages.where(
      sender_type: 'Captain::Assistant',
      sender_id: assistant.id,
      message_type: :outgoing,
      private: false
    )
  end

  def earliest(existing, candidate)
    [existing, candidate].compact.min
  end

  def latest(existing, candidate)
    [existing, candidate].compact.max
  end

  def track_existing_outcome(action)
    safely_track(action) do
      outcome = conversation_outcome
      next unless outcome

      yield outcome
      outcome
    end
  end

  # Outcome tracking is reporting, not product behavior: a tracking bug must
  # never break message delivery or conversation state transitions.
  def safely_track(action)
    yield
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: account).capture_exception
    Rails.logger.error(
      "[CAPTAIN][ConversationOutcomeTracker] Failed to record #{action} for conversation=#{conversation.display_id}: #{e.message}"
    )
    nil
  end
end
