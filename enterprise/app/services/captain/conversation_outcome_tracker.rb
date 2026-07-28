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

    track_existing_outcome(:captain_reply) do |outcome|
      outcome.with_lock do
        outcome.captain_involved_at = earliest(outcome.captain_involved_at, message.created_at)
        outcome.first_captain_reply_at = earliest(outcome.first_captain_reply_at, message.created_at)
        outcome.last_captain_reply_at = [outcome.last_captain_reply_at, message.created_at].compact.max
        outcome.captain_reply_count = public_captain_replies.count
        outcome.first_response_seconds = seconds_since_eligibility(outcome, outcome.first_captain_reply_at)
        outcome.save!
      end
    end
  end

  def record_handoff(at:, reason_category: nil)
    track_existing_outcome(:handoff) do |outcome|
      outcome.with_lock do
        outcome.captain_involved_at = earliest(outcome.captain_involved_at, at)
        assign_first_handoff(outcome, at, reason_category)
        outcome.save!
      end
    end
  end

  def record_human_reply(message:)
    return unless public_human_reply?(message)

    track_existing_outcome(:human_reply) do |outcome|
      next outcome if message.created_at < outcome.eligible_at

      outcome.with_lock do
        outcome.first_human_reply_at = earliest(outcome.first_human_reply_at, message.created_at)
        if outcome.captain_involved_at.present? && outcome.resolved_at.present? && message.created_at <= outcome.resolved_at
          outcome.resolution_type = :assisted
        end
        outcome.save!
      end
    end
  end

  def record_resolution(at:, performed_by:)
    track_existing_outcome(:resolution) do |outcome|
      outcome.with_lock do
        next outcome if outcome.resolved_at.present? && at < outcome.resolved_at

        assign_resolution(outcome, at, performed_by)
        outcome.save!
      end
    end
  end

  def record_reopen(at:)
    track_existing_outcome(:reopen) do |outcome|
      next unless outcome&.resolved_at

      outcome.with_lock do
        next outcome if at <= outcome.resolved_at
        next outcome if [outcome.first_reopened_at, outcome.last_reopened_at].include?(at)

        outcome.first_reopened_at = earliest(outcome.first_reopened_at, at)
        outcome.last_reopened_at = [outcome.last_reopened_at, at].compact.max
        outcome.reopen_count += 1
        outcome.durable_resolved_at = nil
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

  def assign_first_handoff(outcome, at, reason_category)
    return if outcome.handoff_at.present? && outcome.handoff_at <= at

    outcome.handoff_at = at
    outcome.handoff_reason_category = reason_category
  end

  def assign_resolution(outcome, at, performed_by)
    new_resolution = outcome.resolved_at != at
    outcome.captain_involved_at = earliest(outcome.captain_involved_at, captain_involvement_at(outcome, at, performed_by))
    outcome.resolved_at = at
    outcome.resolution_seconds = seconds_since_eligibility(outcome, at)
    outcome.resolution_type = resolution_type(outcome, at, performed_by) if new_resolution || outcome.resolution_type.blank?
    outcome.durable_resolved_at = nil if new_resolution
  end

  def captain_involvement_at(outcome, at, performed_by)
    reply_at = public_captain_replies.where(created_at: ..at).minimum(:created_at)
    handoff_at = outcome.handoff_at if outcome.handoff_at.present? && outcome.handoff_at <= at
    performed_at = at if performed_by == assistant

    [reply_at, handoff_at, performed_at].compact.min
  end

  def resolution_type(outcome, at, performed_by)
    return unless outcome.captain_involved_at.present? && outcome.captain_involved_at <= at
    return :assisted if performed_by.is_a?(User) || human_replied_by?(outcome, at)
    return :autonomous if performed_by == assistant && !handed_off_by?(outcome, at)
  end

  def human_replied_by?(outcome, at)
    outcome.first_human_reply_at.present? && outcome.first_human_reply_at <= at
  end

  def handed_off_by?(outcome, at)
    outcome.handoff_at.present? && outcome.handoff_at <= at
  end

  def seconds_since_eligibility(outcome, at)
    return unless at

    [(at - outcome.eligible_at).to_i, 0].max
  end

  def earliest(existing, candidate)
    [existing, candidate].compact.min
  end

  def track_existing_outcome(action)
    safely_track(action) do
      outcome = conversation_outcome
      next unless outcome

      yield outcome
      outcome
    end
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
