class AddEncryptedApiKeysToAgentBots < ActiveRecord::Migration[7.1]
  def change
    add_column :agent_bots, :openai_api_key, :string
    add_column :agent_bots, :google_api_key, :string
  end
end
