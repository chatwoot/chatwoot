class ChangeIntegrationHookAccessTokenToText < ActiveRecord::Migration[7.1]
  def up
    change_column :integrations_hooks, :access_token, :text
  end

  def down
    change_column :integrations_hooks, :access_token, :string
  end
end
