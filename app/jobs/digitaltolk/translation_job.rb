class Digitaltolk::TranslationJob < ApplicationJob
  queue_as :low

  def perform(message, target_language)
    return unless message
    return if message.translation_status.present? && message.translation_status[target_language] == 'ongoing'

    message.update_translation_status(target_language, 'ongoing')
    Digitaltolk::TranslationService.new(message, target_language).perform
    message.reload.update_translation_status(target_language, 'completed')
  rescue StandardError => e
    Rails.logger.error("TranslationJob failed for message ID #{message.id}: #{e.message}")
    message.update_translation_status(target_language, 'failed')
  end
end
