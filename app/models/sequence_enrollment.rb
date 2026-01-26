class SequenceEnrollment < ApplicationRecord
  belongs_to :conversation
  belongs_to :lead_follow_up_sequence, counter_cache: :enrollments_count
  has_many :enrollment_events, dependent: :destroy
  has_one :active_follow_up, class_name: 'ConversationFollowUp', dependent: :nullify

  after_create :increment_status_counter
  after_update :update_status_counter, if: :saved_change_to_status?
  after_destroy :decrement_status_counter

  validates :status, presence: true, inclusion: { in: %w[active completed cancelled failed] }
  validates :enrolled_at, presence: true

  scope :active, -> { where(status: 'active') }
  scope :completed, -> { where(status: 'completed') }
  scope :cancelled, -> { where(status: 'cancelled') }
  scope :failed, -> { where(status: 'failed') }

  # Mark enrollment as completed
  def complete!(reason = nil)
    update!(
      status: 'completed',
      completed_at: Time.current,
      completion_reason: reason
    )

    # Create completion event
    create_event(
      event_type: 'completed',
      metadata: {
        completion_reason: reason,
        total_steps: current_step,
        duration_seconds: (Time.current - enrolled_at).to_i
      }
    )
  end

  # Mark enrollment as cancelled
  def cancel!(reason = nil)
    update!(
      status: 'cancelled',
      completed_at: Time.current,
      completion_reason: reason
    )

    # Create cancellation event
    create_event(
      event_type: 'cancelled',
      metadata: {
        cancellation_reason: reason,
        steps_completed: current_step
      }
    )
  end

  # Mark enrollment as failed
  def fail!(error_message)
    update!(
      status: 'failed',
      completed_at: Time.current,
      completion_reason: error_message
    )

    # Create failure event
    create_event(
      event_type: 'failed',
      metadata: {
        error_message: error_message,
        steps_completed: current_step
      }
    )
  end

  # Create an event for this enrollment
  def create_event(event_type:, step_id: nil, step_index: nil, metadata: {})
    enrollment_events.create!(
      conversation: conversation,
      lead_follow_up_sequence: lead_follow_up_sequence,
      event_type: event_type,
      step_id: step_id,
      step_index: step_index,
      occurred_at: Time.current,
      metadata: metadata
    )
  end

  # Get timeline of events for this enrollment
  def timeline
    enrollment_events.order(occurred_at: :asc)
  end

  # Check if enrollment is active
  def active?
    status == 'active'
  end

  # Check if enrollment is finished (completed, cancelled, or failed)
  def finished?
    %w[completed cancelled failed].include?(status)
  end

  # Get duration in seconds
  def duration
    return nil unless completed_at

    (completed_at - enrolled_at).to_i
  end

  private

  def increment_status_counter
    update_sequence_counter(status, 1)
  end

  def decrement_status_counter
    try_update_sequence_counter(status, -1)
  end

  def update_status_counter
    old_status, new_status = saved_change_to_status
    try_update_sequence_counter(old_status, -1)
    update_sequence_counter(new_status, 1)
  end

  # Use different name for safe decrement to avoid errors if record is already deleted
  def try_update_sequence_counter(status_name, by)
    update_sequence_counter(status_name, by)
  rescue ActiveRecord::RecordNotFound
    # Ignore if sequence is missing
  end

  def update_sequence_counter(status_name, by)
    return unless status_name.present? && lead_follow_up_sequence_id

    column = "#{status_name}_enrollments_count"
    # We can't check respond_to? on the association easily if it's not loaded,
    # so we rely on the column naming convention.
    
    # Use update_counters to atomic update without triggering model callbacks
    LeadFollowUpSequence.update_counters(lead_follow_up_sequence_id, column => by)
  rescue StandardError => e
    Rails.logger.warn "Failed to update counter #{column}: #{e.message}"
  end
end
