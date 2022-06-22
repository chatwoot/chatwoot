class AddTypeToAgentBots < ActiveRecord::Migration[6.1]
  def up
    change_table :agent_bots, bulk: true do |t|
      t.column :type, :integer, default: 0
      t.column :bot_config, :jsonb, default: {}
    end
  end

  def down
    change_table :agent_bots, bulk: true do |t|
      t.remove :type
      t.remove :bot_config
    end
  end
end
