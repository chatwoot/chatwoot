class Captain::Conversation::ContactMessageTranslationJob < ApplicationJob
  queue_as :default

  def perform(message, target_language)
    Captain::Conversation::ContactMessageTranslationService.new(message: message, target_language: target_language).perform
  end
end
