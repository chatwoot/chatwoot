class CreateAgentBots < ActiveRecord::Migration[6.0]
  def change
    create_table :agent_bots do |t|
      t.integer :account_id
      t.integer :user_id
      t.string :name
      t.string :description
      t.string :outgoing_url

      t.timestamps
    end
  end
end
