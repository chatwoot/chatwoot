class CreateTickets < ActiveRecord::Migration[7.0]
  def change
    create_table :tickets do |t|
      t.string :title, null: false
      t.text :description
      t.integer :status, default: 0, null: false
      t.datetime :resolved_at
      t.bigint :assigned_to
      t.references :user, null: false, foreign_key: true
      t.references :conversation, null: false, foreign_key: true
      t.timestamps
    end

    add_index :tickets, :status
    add_index :tickets, :assigned_to
  end
end
