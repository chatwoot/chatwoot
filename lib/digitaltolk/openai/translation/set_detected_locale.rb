class Digitaltolk::Openai::Translation::SetDetectedLocale
  def initialize(message, target_language_locale, same_language, force: false)
    @message = message
    @target_language_locale = target_language_locale
    @same_language = same_language
    @force = force
  end

  def perform
    set_detected_locale
  end

  private

  def set_detected_locale
    hash = {}

    if previous_detected_locale.blank? || @force
      hash = { @target_language_locale => @same_language }
    else
      hash = previous_detected_locale.dup
      hash[@target_language_locale] = currently_same_language?
    end

    Messages::TranslationBuilder.new(
      @message.reload,
      hash,
      'detected_locale'
    ).perform
  end

  def was_translated_already?
    (translations || {})[@target_language_locale].present?
  end

  def translations
    @message.translations
  end

  def previous_detected_locale
    translations&.dig('detected_locale') || {}
  end

  def detected_to_have_translation?
    return false if previous_detected_locale.blank?

    previous_detected_locale[@target_language_locale] == false
  end

  def currently_same_language?
    return false if detected_to_have_translation?

    @same_language
  end
end
