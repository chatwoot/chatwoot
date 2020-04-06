class CreateAgentBotInboxes < ActiveRecord::Migration[6.0]
  def change
    create_table :agent_bot_inboxes do |t|
      t.integer :inbox_id
      t.integer :agent_bot_id
      t.integer :status, default: 0

      t.timestamps
    end
  end
end
