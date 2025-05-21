class ScheduleHandoffLabelChangeJob < ApplicationJob
  queue_as :high

  def perform(conversation)
    return if conversation.blank?

    handoff_labels = %w[handoff]
    current_handoff_label = conversation.labels.find { |label| handoff_labels.include?(label.name) }&.name
    return unless current_handoff_label

    # Change label from handoff to stark
    begin
      current_labels = (conversation.labels&.map(&:name) || []).compact
      current_labels = (current_labels - [current_handoff_label] + ['stark']).uniq
      conversation.update_labels(current_labels)
      conversation.update_columns(last_handoff_at: nil) # rubocop:disable Rails/SkipsModelValidations
    rescue StandardError => e
      Rails.logger.error("Failed to update labels for conversation #{conversation.id}: #{e.message}")
      raise e
    end
  end
end
