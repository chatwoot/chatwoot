class Messages::TranslationBuilder
  def initialize(message, translated_content, target_language)
    @message = message
    @translated_content = translated_content
    @target_language = target_language
  end

  def perform
    if @translated_content.present?
      translations = {}
      translations[@target_language] = @translated_content
      translations = @message.translations.merge!(translations) if @message.translations.present?
      @message.update!(translations: translations)
    end

    @translated_content
  end
end