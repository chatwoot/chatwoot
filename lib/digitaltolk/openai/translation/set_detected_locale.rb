class Digitaltolk::Openai::Translation::SetDetectedLocale
  def initialize(message, target_language_locale, has_translation)
    @message = message
    @target_language_locale = target_language_locale
    @has_translation = has_translation
  end

  def perform
    set_detected_locale
  end

  private

  def set_detected_locale
    hash = {}

    if previous_detected_locale.blank?
      hash = { @target_language_locale => is_currently_same_language? }
    elsif previous_detected_locale.present?
      hash = previous_detected_locale.dup
      hash[@target_language_locale] = is_currently_same_language?
    end

    Messages::TranslationBuilder.new(
      @message,
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
    previous_detected_locale[@target_language_locale].present? && previous_detected_locale[@target_language_locale] == false
  end

  def is_currently_same_language?
    return false if detected_to_have_translation?

    !@has_translation 
  end
end