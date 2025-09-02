class CreateQueues < ActiveRecord::Migration[7.0]
  def change
    create_table :queues do |t|
      t.references :account, null: false, foreign_key: true
      t.references :department, null: false, foreign_key: true
      t.references :sla_policy, null: true, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.integer :priority, default: 1
      t.boolean :active, default: true
      t.integer :max_capacity
      t.json :routing_rules
      t.json :working_hours

      t.timestamps
    end

    add_index :queues, [:name, :account_id], unique: true
    add_index :queues, :account_id
    add_index :queues, :department_id
    add_index :queues, :priority
  end
end