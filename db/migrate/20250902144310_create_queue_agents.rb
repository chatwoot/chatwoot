class CreateQueueAgents < ActiveRecord::Migration[7.0]
  def change
    create_table :queue_agents do |t|
      t.references :queue, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :queue_agents, [:queue_id, :user_id], unique: true
  end
end