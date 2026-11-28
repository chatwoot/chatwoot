require 'google/cloud/translate/v3'

module Integrations::GoogleTranslate::Client
  class InvalidCredentials < StandardError; end

  def self.build(settings)
    settings = {} unless settings.is_a?(Hash)
    credentials = Integrations::GoogleServiceAccountCredentials.for_client(settings['credentials'], fallback_project_id: settings['project_id'])
    raise InvalidCredentials, I18n.t('errors.google_translate.invalid_credentials') unless credentials

    ::Google::Cloud::Translate::V3::TranslationService::Client.new do |config|
      config.credentials = credentials
    end
  end
end
