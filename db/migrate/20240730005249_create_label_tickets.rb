class CreateLabelTickets < ActiveRecord::Migration[7.0]
  def change
    create_table :label_tickets do |t|
      t.references :ticket, null: false, foreign_key: true
      t.references :label, null: false, foreign_key: true
      t.timestamps
    end

    add_index :label_tickets, [:ticket_id, :label_id], unique: true
  end
end
