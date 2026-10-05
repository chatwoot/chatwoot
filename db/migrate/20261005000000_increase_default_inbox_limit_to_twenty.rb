class IncreaseDefaultInboxLimitToTwenty < ActiveRecord::Migration[7.1]
  OLD_LIMIT = 10
  NEW_LIMIT = 20

  def up
    # ConfigLoader never overwrites existing configs, so bump the installation default here.
    # Only the old default is touched; custom values on self-hosted installs are left alone.
    config = InstallationConfig.find_by(name: 'ACCOUNT_INBOXES_LIMIT')
    if config&.value.to_s == OLD_LIMIT.to_s
      config.value = NEW_LIMIT
      config.save!
      GlobalConfig.clear_cache
    end

    # rubocop:disable Rails/SkipsModelValidations
    Account.where("limits ->> 'inboxes' = ?", OLD_LIMIT.to_s)
           .update_all(["limits = jsonb_set(limits, '{inboxes}', ?::jsonb)", NEW_LIMIT.to_json])
    # rubocop:enable Rails/SkipsModelValidations
  end
end
