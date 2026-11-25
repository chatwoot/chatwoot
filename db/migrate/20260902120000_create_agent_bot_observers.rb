class CreateAgentBotObservers < ActiveRecord::Migration[7.1]
  def change
    create_table :agent_bot_observers do |t|
      t.references :account, null: false, index: true
      t.references :inbox, null: false, index: false
      t.references :agent_bot, null: false, index: true
      t.timestamps
    end
    add_index :agent_bot_observers, [:inbox_id, :agent_bot_id], unique: true
  end
end
