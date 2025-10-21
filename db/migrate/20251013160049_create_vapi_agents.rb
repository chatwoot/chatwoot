class CreateVapiAgents < ActiveRecord::Migration[7.1]
  def change
    create_table :vapi_agents do |t|
      t.references :inbox, null: false, foreign_key: true, index: true
      t.references :account, null: false, foreign_key: true, index: true
      t.string :vapi_agent_id, null: false
      t.string :name, null: false
      t.string :phone_number
      t.jsonb :settings, default: {}
      t.boolean :active, default: true

      t.timestamps
    end

    add_index :vapi_agents, :vapi_agent_id, unique: true
  end
end
