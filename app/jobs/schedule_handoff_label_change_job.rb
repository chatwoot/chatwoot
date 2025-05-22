class ScheduleHandoffLabelChangeJob < ApplicationJob
  queue_as :high

  def perform(conversation)
    return if conversation.blank?

    current_handoff_label = find_handoff_label(conversation)
    return unless current_handoff_label

    update_conversation_labels(conversation, current_handoff_label)
  end

  private

  def find_handoff_label(conversation)
    handoff_labels = %w[handoff]
    conversation.labels.find { |label| handoff_labels.include?(label.name) }&.name
  end

  def update_conversation_labels(conversation, current_handoff_label)
    current_labels = prepare_labels(conversation, current_handoff_label)
    save_conversation_changes(conversation, current_labels)
  rescue StandardError => e
    log_error(conversation, e)
    raise e
  end

  def prepare_labels(conversation, current_handoff_label)
    current_labels = (conversation.labels&.map(&:name) || []).compact
    (current_labels - [current_handoff_label] + ['stark']).uniq
  end

  def save_conversation_changes(conversation, current_labels)
    conversation.update_labels(current_labels)
    conversation.update_columns(last_handoff_at: nil) # rubocop:disable Rails/SkipsModelValidations
  end

  def log_error(conversation, error)
    Rails.logger.error("Failed to update labels for conversation #{conversation.id}: #{error.message}")
  end
end
