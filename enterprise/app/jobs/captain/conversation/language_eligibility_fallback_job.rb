class Captain::Conversation::LanguageEligibilityFallbackJob < ApplicationJob
  def perform(conversation, message)
    return unless conversation.pending?
    return unless conversation.additional_attributes[Captain::Assistant::LANGUAGE_ELIGIBILITY_PENDING_KEY]

    additional_attributes = conversation.additional_attributes.except(Captain::Assistant::LANGUAGE_ELIGIBILITY_PENDING_KEY)
    conversation.bot_handoff!
    conversation.update!(additional_attributes: additional_attributes)
    ::MessageTemplates::HookExecutionService.new(message: message).perform
  end
end
