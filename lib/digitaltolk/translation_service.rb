class Digitaltolk::TranslationService
  def initialize(message, target_language)
    @message = message
    @target_language = target_language
  end

  def perform
    if digitaltolk_translation_enabled?
      format_outgoing_email!

      if email_content.present?
        # If the email content is HTML, we need to handle it differently
        Digitaltolk::Openai::HtmlTranslation::TranslateByBatch.new(message, target_language).perform
      else
        response_data = Digitaltolk::Openai::Translation.new.perform(message.content, target_language)

        return if response_data.blank?
        return if response_data['translated_message'].blank?

        same_content = message.content.to_s.strip.downcase == response_data['translated_message'].to_s.strip.downcase

        Digitaltolk::Openai::Translation::SetDetectedLocale.new(
          message,
          target_language,
          !same_content
        )

        return if response_data['translated_locale'] != target_language
        return if same_content

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

  def email_content
    message.email&.dig('html_content', 'full')
  end

  def format_outgoing_email!
    return unless message.outgoing?
    return if email_content.present?

    # specifically autoformat booking emails
    is_a_booking_email = message.content.include?('Bokningsnummer:') ||
                         message.content.include?('DigitalTolk kundservice')

    return unless is_a_booking_email

    Digitaltolk::FormatOutgoingEmailService.new(message).perform
    message.reload
  rescue StandardError => e
    Rails.logger.error("Failed to format outgoing email: #{e.message}")
  end

  def account
    @message.account
  end

  def digitaltolk_translation_enabled?
    account.feature_enabled?(:ai_translation)
  end
end
