class CreateAgentBots < ActiveRecord::Migration[6.0]
  def change
    create_table :agent_bots do |t|
      t.string :name
      t.string :description
      t.string :outgoing_url
      t.string :auth_token, unique: true

      t.timestamps
    end
  end
end
