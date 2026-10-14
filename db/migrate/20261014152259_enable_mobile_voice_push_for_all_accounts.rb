# Turns mobile_voice_push on in the stored feature defaults and for every account. A deploy only
# adds new feature defaults, so the existing default is changed here. It runs outside a transaction:
# the default is saved first, so accounts created from then on start with the flag, and accounts
# are updated in batches that each commit on their own, skipping those that already have it.
class EnableMobileVoicePushForAllAccounts < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def up
    config = InstallationConfig.find_by(name: 'ACCOUNT_LEVEL_FEATURE_DEFAULTS')
    if config && config.value.present?
      config.value = config.value.map { |feature| feature['name'] == 'mobile_voice_push' ? feature.merge('enabled' => true) : feature }
      config.save!
    end
    GlobalConfig.clear_cache

    column, mapping = Account.flag_mapping.find { |_column, flags| flags.key?(:feature_mobile_voice_push) }
    bit = mapping[:feature_mobile_voice_push]
    Account.where("#{column} & #{bit} = 0").in_batches(of: 1000) do |batch|
      batch.update_all("#{column} = #{column} | #{bit}") # rubocop:disable Rails/SkipsModelValidations
    end
  end
end
