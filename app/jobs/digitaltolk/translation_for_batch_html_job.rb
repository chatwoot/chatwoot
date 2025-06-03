class Digitaltolk::TranslationForBatchHtmlJob < ApplicationJob
  queue_as :low

  def perform(message, target_language, index)
    return unless message

    Digitaltolk::Openai::HtmlTranslation::Translate.new.perform(message, target_language, batch_index: index)
  end
end
