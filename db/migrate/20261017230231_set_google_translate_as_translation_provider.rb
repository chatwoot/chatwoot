class SetGoogleTranslateAsTranslationProvider < ActiveRecord::Migration[7.2]
  def up
    Account.where(id: Integrations::Hook.where(app_id: 'google_translate').select(:account_id)).find_each do |account|
      next if account.translation_provider.present?

      account.update!(translation_provider: 'google_translate')
    end
  end

  def down
    Account.find_each do |account|
      account.update!(translation_provider: nil) if account.translation_provider == 'google_translate'
    end
  end
end
