class Captain::ConversationOutcomeTracker
  pattr_initialize [:conversation!, :assistant!]

  def record_eligibility(at:)
    safely_track(:eligibility) do
      next unless account.feature_enabled?('captain_integration_v2')

      outcome = find_or_create_outcome(at)

      outcome.with_lock do
        outcome.inbox = conversation.inbox
        outcome.eligible_at = [outcome.eligible_at, at].compact.min
        outcome.save! if outcome.changed?
      end

      outcome
    end
  end

  def record_captain_reply(message:)
    return unless public_captain_reply?(message)

    safely_track(:captain_reply) do
      outcome = conversation_outcome
      next unless outcome

      outcome.with_lock do
        outcome.captain_involved_at = earliest(outcome.captain_involved_at, message.created_at)
        outcome.first_captain_reply_at = earliest(outcome.first_captain_reply_at, message.created_at)
        outcome.last_captain_reply_at = latest(outcome.last_captain_reply_at, message.created_at)
        outcome.captain_reply_count = public_captain_replies.count
        outcome.first_response_seconds = seconds_since_eligibility(outcome, outcome.first_captain_reply_at)
        outcome.save!
      end

      outcome
    end
  end

  def record_handoff(at:, reason_category: nil)
    safely_track(:handoff) do
      outcome = conversation_outcome
      next unless outcome

      outcome.with_lock do
        outcome.captain_involved_at = earliest(outcome.captain_involved_at, at)
        assign_first_handoff(outcome, at, reason_category)
        outcome.save!
      end

      outcome
    end
  end

  private

  def account
    conversation.account
  end

  def conversation_outcome
    Captain::ConversationOutcome.find_by(
      account: account,
      assistant: assistant,
      conversation: conversation
    )
  end

  def find_or_create_outcome(eligible_at)
    conversation_outcome || Captain::ConversationOutcome.create!(
      account: account,
      assistant: assistant,
      conversation: conversation,
      inbox: conversation.inbox,
      eligible_at: eligible_at
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

  def public_captain_replies
    conversation.messages.where(
      sender_type: 'Captain::Assistant',
      sender_id: assistant.id,
      message_type: :outgoing,
      private: false
    )
  end

  def assign_first_handoff(outcome, at, reason_category)
    return if outcome.handoff_at.present? && outcome.handoff_at <= at

    outcome.handoff_at = at
    outcome.handoff_reason_category = reason_category
  end

  def seconds_since_eligibility(outcome, at)
    return unless at

    [(at - outcome.eligible_at).to_i, 0].max
  end

  def earliest(existing, candidate)
    [existing, candidate].compact.min
  end

  def latest(existing, candidate)
    [existing, candidate].compact.max
  end

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
