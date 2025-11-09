# frozen_string_literal: true

class AutoLabelListener < BaseListener
  def message_created(event)
    message = event.data[:message]
    conversation = message.conversation

    return unless should_auto_label?(conversation, message)

    Labels::AutoLabelJob.perform_later(conversation.id)
  end

  private

  def should_auto_label?(conversation, message)
    return false unless message.incoming?
    return false unless auto_label_enabled?(conversation.account)
    return false if conversation.label_list.any?
    return false unless threshold_met?(conversation)

    true
  end

  def auto_label_enabled?(account)
    account.settings.dig('auto_label_enabled') == true
  end

  def threshold_met?(conversation)
    threshold = conversation.account.settings.dig('auto_label_message_threshold') || 3
    conversation.messages.incoming.count >= threshold
  end
end
