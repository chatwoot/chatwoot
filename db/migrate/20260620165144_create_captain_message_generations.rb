class CreateCaptainMessageGenerations < ActiveRecord::Migration[7.1]
  def change
    create_table :captain_message_generations do |t|
      t.references :message, null: false, index: { unique: true }
      t.references :account, null: false
      t.references :conversation, null: false
      t.references :assistant, null: false
      t.text :reasoning
      t.string :model
      t.jsonb :citations, null: false, default: []
      t.jsonb :generation_path, null: false, default: []

      t.timestamps
    end
  end
end
