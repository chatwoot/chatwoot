class CreateTicketTasks < ActiveRecord::Migration[7.1]
  def change
    create_table :ticket_tasks do |t|
      t.references :account, null: false, index: true, foreign_key: true
      t.references :ticket, null: false, index: true, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.integer :status, null: false, default: 0
      t.references :assignee, foreign_key: { to_table: :users }
      t.references :team, foreign_key: true
      t.datetime :due_at
      t.datetime :completed_at
      t.references :created_by, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :ticket_tasks, [:ticket_id, :status]
  end
end
