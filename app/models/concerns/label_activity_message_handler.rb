module LabelActivityMessageHandler
  extend ActiveSupport::Concern

  # Move constant to module level
  EXCLUDED_LABEL_PATTERNS = %w[pre-sale-query calling-nudge].freeze

  private

  def create_label_added(user_name, labels = [])
    create_label_change_activity('added', user_name, labels)
  end

  def create_label_removed(user_name, labels = [])
    create_label_change_activity('removed', user_name, labels)
  end

  def create_label_change_activity(change_type, user_name, labels = [])
    # Filter out excluded labels
    filtered_labels = labels.reject do |label|
      EXCLUDED_LABEL_PATTERNS.any? { |pattern| label.include?(pattern) }
    end

    return unless filtered_labels.size.positive?

    content = I18n.t("conversations.activity.labels.#{change_type}",
                     user_name: user_name,
                     labels: filtered_labels.join(', '))
    ::Conversations::ActivityMessageJob.perform_later(self, activity_message_params(content)) if content
  end
end
