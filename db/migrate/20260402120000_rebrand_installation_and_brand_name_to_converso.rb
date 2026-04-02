class RebrandInstallationAndBrandNameToConverso < ActiveRecord::Migration[7.1]
  def up
    %w[INSTALLATION_NAME BRAND_NAME].each do |name|
      config = InstallationConfig.find_by(name: name)
      next unless config
      next unless config.value.to_s == 'Chatwoot'

      config.update!(value: 'Converso')
    end

    GlobalConfig.clear_cache
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
