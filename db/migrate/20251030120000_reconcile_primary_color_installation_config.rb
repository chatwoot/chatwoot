class ReconcilePrimaryColorInstallationConfig < ActiveRecord::Migration[7.0]
  def up
    ConfigLoader.new.process(reconcile_only_new: true)
    GlobalConfig.clear_cache
  end

  def down
    InstallationConfig.find_by(name: 'PRIMARY_COLOR_HEX')&.destroy!
    GlobalConfig.clear_cache
  end
end
