class Digitaltolk::TranslationService
  def initialize(message, target_language)
    @message = message
    @target_language = target_language
  end

  def perform
    if digitaltolk_translation_enabled?
      response_data = Digitaltolk::Openai::Translation.new.perform(message.content, Current.account.translation_language)

      if response_data.present?
        Messages::TranslationBuilder.new(
          message,
          response_data['translated_message'],
          response_data['translated_locale']
        ).perform
      end
    else
      translated_content = Integrations::GoogleTranslate::ProcessorService.new(
        message: message,
        target_language: target_language
      ).perform

      Messages::TranslationBuilder.new(
        message,
        translated_content,
        target_language
      ).perform
    end
  end

  private

  attr_reader :message, :target_language
  
  def digitaltolk_translation_enabled?
    Current.account.feature_enabled?(:ai_translation)
  end
end