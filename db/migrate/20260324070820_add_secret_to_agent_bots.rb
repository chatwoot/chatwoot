class AddSecretToAgentBots < ActiveRecord::Migration[7.1]
  def change
    add_column :agent_bots, :secret, :string
  end
end
