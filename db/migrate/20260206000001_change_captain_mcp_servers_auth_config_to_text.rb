class ChangeCaptainMcpServersAuthConfigToText < ActiveRecord::Migration[7.1]
  def up
    change_column :captain_mcp_servers, :auth_config, :text, default: nil
  end

  def down
    change_column :captain_mcp_servers, :auth_config, :jsonb, default: {}
  end
end
