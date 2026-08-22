class CreateCaptainSimpleReplies < ActiveRecord::Migration[7.1]
  def change
    create_table :captain_simple_replies do |t|
      t.string :name, null: false
      t.jsonb :keywords, null: false, default: []
      t.text :reply, null: false
      t.integer :match_type, null: false, default: 0
      t.boolean :enabled, null: false, default: true

      t.references :account, null: false, foreign_key: true
      t.references :assistant, null: false, foreign_key: { to_table: :captain_assistants }

      t.timestamps
    end

    add_index :captain_simple_replies, [:assistant_id, :enabled]
  end
end
