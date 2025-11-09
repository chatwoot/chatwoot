# frozen_string_literal: true

class AutoClassificationListener < BaseListener
  def message_created(event)
    message = event.data[:message]
    conversation = message.conversation

    return unless should_auto_classify?(conversation, message)

    AutoClassificationJob.perform_later(conversation.id)
  end

  private

  def should_auto_classify?(conversation, message)
    return false unless message.incoming?
    return false unless auto_classification_enabled?(conversation.account)
    return false unless threshold_met?(conversation)
    return false if already_classified?(conversation)

    true
  end

  def auto_classification_enabled?(account)
    account.settings.dig('auto_label_enabled') == true ||
      account.settings.dig('auto_team_enabled') == true
  end

  def threshold_met?(conversation)
    threshold = conversation.account.settings.dig('auto_label_message_threshold') || 3
    conversation.messages.incoming.count >= threshold
  end

  def already_classified?(conversation)
    # Only skip if both are already assigned (when both features are enabled)
    account = conversation.account

    label_done = !account.settings.dig('auto_label_enabled') || conversation.label_list.any?
    team_done = !account.settings.dig('auto_team_enabled') || conversation.team_id.present?

    label_done && team_done
  end
end
