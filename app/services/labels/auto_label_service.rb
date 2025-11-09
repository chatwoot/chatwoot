# frozen_string_literal: true

class Labels::AutoLabelService
  pattr_initialize [:conversation!]

  def perform
    return unless auto_label_enabled?
    return unless openai_api_key_present?
    return if conversation.label_list.any?

    suggested_labels = fetch_label_suggestions
    return if suggested_labels.blank?

    apply_labels(suggested_labels)
    Rails.logger.info("Auto-labeled conversation #{conversation.id} with: #{suggested_labels.join(', ')}")
  rescue StandardError => e
    Rails.logger.error("Auto-labeling failed for conversation #{conversation.id}: #{e.message}")
    raise # Re-raise for job retry
  end

  private

  def auto_label_enabled?
    account.settings.dig('auto_label_enabled') == true
  end

  def openai_api_key_present?
    ENV['OPENAI_API_KEY'].present?
  end

  def fetch_label_suggestions
    classifier = Labels::OpenaiClassifierService.new(
      conversation: conversation,
      account: account
    )

    result = classifier.suggest_labels
    result[:labels] || []
  end

  def apply_labels(label_names)
    conversation.add_labels(label_names)
  end

  def account
    @account ||= conversation.account
  end
end
