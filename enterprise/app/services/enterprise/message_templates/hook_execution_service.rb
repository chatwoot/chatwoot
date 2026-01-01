# frozen_string_literal: true

module Enterprise::MessageTemplates::HookExecutionService
  # Captain feature has been removed and replaced by Aloo.
  # Aloo uses AlooAgentListener for message handling instead of hook execution service.
  # This module now only adds Aloo-aware checks for greetings/templates.

  def should_send_greeting?
    return false if aloo_handling_conversation?

    super
  end

  def should_send_out_of_office_message?
    return false if aloo_handling_conversation?

    super
  end

  def should_send_email_collect?
    return false if aloo_handling_conversation?

    super
  end

  private

  def aloo_handling_conversation?
    conversation.pending? && inbox.aloo_assistant&.active?
  end
end
