class ConvertIntegrationHookSettingsField < ActiveRecord::Migration[6.0]
  def change
    remove_column :integrations_hooks, :settings, :text
    add_column :integrations_hooks, :settings, :jsonb, default: {}
  end
end
