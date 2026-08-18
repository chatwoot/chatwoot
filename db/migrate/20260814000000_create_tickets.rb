class CreateTickets < ActiveRecord::Migration[7.1]
  def change
    create_table :tickets do |t|
      t.references :account, null: false, index: true, foreign_key: true
      t.references :conversation, null: false, index: { unique: true }, foreign_key: true
      t.string :subject, null: false
      t.string :ticket_type
      t.integer :waiting_on, null: false, default: 0
      t.string :waiting_note
      t.datetime :due_at
      t.datetime :closed_at
      t.references :created_by, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
