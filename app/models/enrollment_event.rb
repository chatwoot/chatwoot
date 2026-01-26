class EnrollmentEvent < ApplicationRecord
  belongs_to :sequence_enrollment
  belongs_to :conversation
  belongs_to :lead_follow_up_sequence

  validates :event_type, presence: true
  validates :occurred_at, presence: true

  # Event types available
  EVENT_TYPES = %w[
    enrolled
    step_executed
    step_failed
    message_sent
    ai_response_received
    template_sent
    sms_sent
    label_added
    label_removed
    agent_assigned
    team_assigned
    pipeline_status_updated
    webhook_called
    paused
    resumed
    completed
    cancelled
    failed
    re_enrolled
  ].freeze

  validates :event_type, inclusion: { in: EVENT_TYPES }

  scope :by_conversation, ->(conversation_id) { where(conversation_id: conversation_id) }
  scope :by_sequence, ->(sequence_id) { where(lead_follow_up_sequence_id: sequence_id) }
  scope :by_enrollment, ->(enrollment_id) { where(sequence_enrollment_id: enrollment_id) }
  scope :by_type, ->(type) { where(event_type: type) }
  scope :recent, -> { order(occurred_at: :desc) }
  scope :chronological, -> { order(occurred_at: :asc) }

  # Get step name from metadata if available
  def step_name
    metadata&.dig('step_name')
  end

  # Get human-readable description
  def description
    case event_type
    when 'enrolled'
      "Enrolled in sequence '#{lead_follow_up_sequence.name}'"
    when 'step_executed'
      "Executed step: #{step_name || step_id}"
    when 'step_failed'
      "Step failed: #{metadata&.dig('error_message')}"
    when 'message_sent'
      "Message sent via #{metadata&.dig('channel')}"
    when 'template_sent'
      "Template '#{metadata&.dig('template_name')}' sent"
    when 'ai_response_received'
      "AI response received"
    when 'sms_sent'
      "SMS sent"
    when 'label_added'
      "Labels added: #{metadata&.dig('labels')&.join(', ')}"
    when 'label_removed'
      "Labels removed: #{metadata&.dig('labels')&.join(', ')}"
    when 'agent_assigned'
      "Agent assigned: #{metadata&.dig('agent_name')}"
    when 'team_assigned'
      "Team assigned: #{metadata&.dig('team_name')}"
    when 'pipeline_status_updated'
      "Pipeline status updated to: #{metadata&.dig('status_name')}"
    when 'webhook_called'
      "Webhook called: #{metadata&.dig('url')}"
    when 'completed'
      "Sequence completed: #{metadata&.dig('completion_reason')}"
    when 'cancelled'
      "Sequence cancelled: #{metadata&.dig('cancellation_reason')}"
    when 'failed'
      "Sequence failed: #{metadata&.dig('error_message')}"
    when 're_enrolled'
      "Re-enrolled in sequence"
    else
      event_type.humanize
    end
  end

  # Check if this is a step event
  def step_event?
    %w[step_executed step_failed].include?(event_type)
  end

  # Check if this is a message event
  def message_event?
    %w[message_sent template_sent sms_sent ai_response_received].include?(event_type)
  end

  # Check if this is a terminal event (ends the enrollment)
  def terminal_event?
    %w[completed cancelled failed].include?(event_type)
  end
end
