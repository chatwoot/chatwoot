# frozen_string_literal: true

class Labels::AutoLabelService
  attr_reader :conversation

  def initialize(conversation)
    @conversation = conversation
  end

  def perform
    return unless auto_label_enabled?
    return if conversation.label_list.any?

    suggested_label_id = fetch_label_suggestion
    return if suggested_label_id.nil?

    label = apply_label(suggested_label_id)
    Rails.logger.info("Auto-labeled conversation #{conversation.id} with: #{label.title}") if label
  rescue StandardError => e
    Rails.logger.error("Auto-labeling failed for conversation #{conversation.id}: #{e.message}")
    raise # Re-raise for job retry
  end

  private

  def auto_label_enabled?
    account.settings.dig('auto_label_enabled') == true
  end

  def fetch_label_suggestion
    classifier = Labels::OpenaiClassifierService.new(conversation)

    classifier.suggest_label
  end

  def apply_label(label_id)
    label = account.labels.find_by(id: label_id)
    return nil unless label

    conversation.add_labels([label.title])
    label
  end

  def account
    @account ||= conversation.account
  end
end
