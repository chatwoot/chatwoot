# Swaps "Chatwoot" in backend translations (all locales) for the configured
# installation name, mirroring replaceInstallationNameInTranslation on the frontend.
module InstallationNameTranslation
  def translate(locale, key, options = {})
    result = super
    return result unless result.is_a?(String) && result.include?('Chatwoot')

    result.gsub('Chatwoot', GlobalConfig.get_value('INSTALLATION_NAME'))
  end
end

Rails.application.config.after_initialize do
  I18n.backend.class.prepend(InstallationNameTranslation)
end
