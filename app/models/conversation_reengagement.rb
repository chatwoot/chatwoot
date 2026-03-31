class ConversationReengagement < ApplicationRecord
  belongs_to :conversation
  belongs_to :agent_bot

  STATUSES = %w[active suppressed completed cancelled_reply cancelled_keyword cancelled_api].freeze
  PROCESSING_TIMEOUT = 15.minutes
  DEBOUNCE_WINDOW = 10.minutes

  validates :conversation_id, uniqueness: true
  validates :status, presence: true, inclusion: { in: STATUSES }

  scope :active,     -> { where(status: 'active') }
  scope :suppressed, -> { where(status: 'suppressed') }

  scope :pending_execution, lambda {
    active
      .where('next_fire_at <= ?', Time.current)
      .where(processing_started_at: nil)
  }

  # ─── State transitions ────────────────────────────────────────────────

  def reactivate!(trigger_started_at:)
    config = reengagement_config
    return unless config

    attempts = config['attempts'] || []
    return if attempts.empty?

    update!(
      status: 'active',
      current_attempt: 0,
      trigger_started_at: trigger_started_at,
      next_fire_at: trigger_started_at + delay_duration(attempts[0]),
      last_attempt_fired_at: nil,
      processing_started_at: nil,
      metadata: metadata.merge('reactivation_count' => (metadata['reactivation_count'] || 0) + 1)
    )
  end

  def suppress!(sequence_id: nil)
    meta = metadata.merge('suppressed_by_sequence_id' => sequence_id, 'suppressed_at' => Time.current)
    update!(status: 'suppressed', processing_started_at: nil, metadata: meta)
  end

  def cancel!(reason:, extra_meta: {})
    update!(
      status: reason,
      processing_started_at: nil,
      metadata: metadata.merge({ 'cancelled_at' => Time.current }.merge(extra_meta))
    )
  end

  def mark_processing!
    update_column(:processing_started_at, Time.current)
  end

  def clear_processing!
    update_column(:processing_started_at, nil)
  end

  # Advance to next attempt after firing. Returns true if completed.
  def advance!
    config = reengagement_config
    attempts = config&.dig('attempts') || []
    next_index = current_attempt + 1

    update!(
      current_attempt: next_index,
      last_attempt_fired_at: Time.current,
      processing_started_at: nil,
      metadata: append_attempt_history
    )

    if next_index >= attempts.length
      update!(status: 'completed')
      return true
    end

    update!(next_fire_at: trigger_started_at + delay_duration(attempts[next_index]))
    false
  end

  # True if the last attempt message was fired recently (debounce window)
  def within_debounce_window?
    last_attempt_fired_at.present? &&
      (Time.current - last_attempt_fired_at) < DEBOUNCE_WINDOW
  end

  # ─── Config helpers ──────────────────────────────────────────────────

  def reengagement_config
    agent_bot.agent_behavior_config&.dig('proactive_reengagement')
  end

  def stop_on_any_reply?
    reengagement_config&.dig('stop_conditions', 'on_any_reply') == true
  end

  def stop_on_resolved?
    reengagement_config&.dig('stop_conditions', 'on_resolved') == true
  end

  def stop_on_agent_assigned?
    reengagement_config&.dig('stop_conditions', 'on_agent_assigned') == true
  end

  def stop_keywords
    config = reengagement_config&.dig('stop_keywords') || {}
    phrases = config['phrases'] || []
    case_insensitive = config.fetch('case_insensitive', true)
    [phrases, case_insensitive]
  end

  def reactivates_on_bot_reply?
    reengagement_config&.dig('reactivation', 'on_bot_reply') == true
  end

  def excluded_from_reactivation?(cancel_status)
    excluded = reengagement_config&.dig('reactivation', 'exclude_if_cancelled_by') || []
    key = cancel_status.to_s.delete_prefix('cancelled_')
    excluded.include?(key)
  end

  # ─── Private ─────────────────────────────────────────────────────────

  private

  def delay_duration(attempt)
    value = attempt['delay_value'].to_i
    unit  = attempt['delay_unit'].to_s

    case unit
    when 'minutes' then value.minutes
    when 'hours'   then value.hours
    when 'days'    then value.days
    else value.minutes
    end
  end

  def append_attempt_history
    history = metadata['attempts_history'] || []
    history << { 'attempt' => current_attempt + 1, 'fired_at' => Time.current.iso8601 }
    metadata.merge('attempts_history' => history)
  end
end
