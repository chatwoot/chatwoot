class Digitaltolk::TranslationJob < ApplicationJob
  queue_as :low

  def perform(message, target_language)
    return unless message

    Digitaltolk::TranslationService.new(message, target_language).perform
  end
end
