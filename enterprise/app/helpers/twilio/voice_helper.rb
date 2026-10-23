module Twilio::VoiceHelper
  # Languages supported by Twilio's basic voices. Other account languages retain the English default.
  ANNOUNCEMENT_LANGUAGES = {
    'en' => 'en-US', 'en-GB' => 'en-GB', 'de' => 'de-DE',
    'es' => 'es-ES', 'fr' => 'fr-FR', 'it' => 'it-IT'
  }.freeze

  def out_of_hours_call_language(inbox)
    locale = inbox.account.locale.tr('_', '-')
    ANNOUNCEMENT_LANGUAGES.fetch(locale) { ANNOUNCEMENT_LANGUAGES.fetch(locale.split('-').first, 'en-US') }
  end
end
