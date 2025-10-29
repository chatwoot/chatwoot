# frozen_string_literal: true

# Load custom CommMate translations
Rails.application.config.after_initialize do
  custom_locale_path = Rails.root.join('custom/locales')

  next unless Dir.exist?(custom_locale_path)

  I18n.load_path += Dir[custom_locale_path.join('*.yml')]
  I18n.reload!
end

