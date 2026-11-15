# Turns mobile_voice_push on in the stored feature defaults and for every account. A deploy only
# adds new feature defaults, so the existing default is changed here. It runs outside a transaction:
# the default is saved first, so accounts created from then on start with the flag, and accounts
# are updated in batches that each commit on their own, skipping those that already have it.
class EnableMobileVoicePushForAllAccounts < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def up
    enable_default
    GlobalConfig.clear_cache

    column, mapping = Account.flag_mapping.find { |_column, flags| flags.key?(:feature_mobile_voice_push) }
    bit = mapping[:feature_mobile_voice_push]
    Account.where("#{column} & #{bit} = 0").in_batches(of: 1000) do |batch|
      batch.update_all("#{column} = #{column} | #{bit}") # rubocop:disable Rails/SkipsModelValidations
    end
  end

  private

  # The stored defaults may lack the entry (an installation upgrading past the version that added
  # it) or be missing altogether; the config loader that fills those in runs after migrations
  def enable_default
    entry = YAML.safe_load(Rails.root.join('config/features.yml').read).find { |feature| feature['name'] == 'mobile_voice_push' }
    config = InstallationConfig.find_or_initialize_by(name: 'ACCOUNT_LEVEL_FEATURE_DEFAULTS')
    others = Array(config.value).reject { |feature| feature['name'] == 'mobile_voice_push' }
    config.value = others + [entry.merge('enabled' => true)]
    config.locked = true if config.new_record?
    config.save!
  end
end
