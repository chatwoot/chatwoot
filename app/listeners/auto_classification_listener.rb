# frozen_string_literal: true

class AutoClassificationListener < BaseListener
  MESSAGE_THRESHOLD = 3

  def message_created(event)
    message = event.data[:message]
    conversation = message.conversation

    return unless should_auto_classify?(conversation, message)

    AutoClassificationJob.perform_later(conversation.id)
  end

  private

  def should_auto_classify?(conversation, message)
    return false unless message.incoming?
    return false unless auto_classification_available?(conversation.account)
    return false unless threshold_met?(conversation)
    return false if already_classified?(conversation)

    true
  end

  def auto_classification_available?(account)
    account.labels.exists?(allow_auto_assign: true) ||
      account.teams.exists?(allow_auto_assign: true)
  end

  def threshold_met?(conversation)
    conversation.messages.incoming.count >= MESSAGE_THRESHOLD
  end

  def already_classified?(conversation)
    conversation.label_list.any? && conversation.team_id.present?
  end
end
