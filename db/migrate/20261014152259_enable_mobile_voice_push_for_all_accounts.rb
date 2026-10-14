# Turns mobile_voice_push on in the stored feature defaults and for every account. A deploy only
# adds new feature defaults, so the existing default is changed here; accounts are updated in
# one statement rather than one save each.
class EnableMobileVoicePushForAllAccounts < ActiveRecord::Migration[7.0]
  def up
    config = InstallationConfig.find_by(name: 'ACCOUNT_LEVEL_FEATURE_DEFAULTS')
    if config && config.value.present?
      config.value = config.value.map { |feature| feature['name'] == 'mobile_voice_push' ? feature.merge('enabled' => true) : feature }
      config.save!
    end

    column, mapping = Account.flag_mapping.find { |_column, flags| flags.key?(:feature_mobile_voice_push) }
    Account.update_all("#{column} = #{column} | #{mapping[:feature_mobile_voice_push]}") # rubocop:disable Rails/SkipsModelValidations

    GlobalConfig.clear_cache
  end
end
