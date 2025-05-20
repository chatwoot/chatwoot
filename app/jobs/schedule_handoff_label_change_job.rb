class ScheduleHandoffLabelChangeJob < ApplicationJob
  queue_as :high

  def perform(conversation)
    return if conversation.blank?

    handoff_labels = %w[handoff human]
    current_handoff_label = conversation.labels.find { |label| handoff_labels.include?(label.name) }&.name
    return unless current_handoff_label

    # Change label to stark after 4 hours
    conversation.label_list.remove(current_handoff_label)
    conversation.label_list.add('stark')
    conversation.last_handoff_at = nil
    conversation.save!
  end
end
