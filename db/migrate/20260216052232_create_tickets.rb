class CreateTickets < ActiveRecord::Migration[7.1]
  def change
    create_table :tickets do |t|
      t.references :account, null: false, foreign_key: true
      t.references :contact, foreign_key: true
      t.references :conversation, foreign_key: true
      t.string :subject, null: false
      t.text :description
      t.string :priority
      t.string :classification
      t.jsonb :external_ids, default: {}
      t.jsonb :metadata, default: {}

      t.timestamps
    end
  end
end
