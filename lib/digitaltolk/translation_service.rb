class Digitaltolk::TranslationService
  def initialize(message, target_language)
    @message = message
    @target_language = target_language
  end

  def perform
    if digitaltolk_translation_enabled?
      email_content = message.email&.dig('html_content', 'full')

      if email_content.present?
        # If the email content is HTML, we need to handle it differently
        # Schedule jobs for HTML translation
        Digitaltolk::Openai::HtmlTranslation::ScheduleJobs.new(message, target_language).perform
      else
        [target_language, other_language].each do |target_locale|
          response_data = Digitaltolk::Openai::Translation.new.perform(message.content, target_locale)

          next if response_data.blank?
          next if response_data['translated_message'].blank?

          same_content = message.content.to_s.strip.downcase == response_data['translated_message'].to_s.strip.downcase

          Digitaltolk::Openai::Translation::SetDetectedLocale.new(
            message,
            target_locale,
            !same_content
          )

          next if response_data['translated_locale'] != target_locale
          next if same_content

          Messages::TranslationBuilder.new(
            message,
            response_data['translated_message'],
            response_data['translated_locale']
          ).perform
        end
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

  def account
    @message.account
  end

  def digitaltolk_translation_enabled?
    account.feature_enabled?(:ai_translation)
  end

  def other_language
    target_language.to_s.include?('en') ? 'sv' : 'en'
  end
end
