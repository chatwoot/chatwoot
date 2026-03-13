class CreateConversationClassifications < ActiveRecord::Migration[7.1]
  def change
    create_table :conversation_classifications do |t|
      t.references :account, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :position, default: 0, null: false
      t.timestamps
    end

    add_index :conversation_classifications, [:account_id, :name], unique: true

    add_column :conversations, :classification_id, :bigint
    add_column :conversations, :closing_note, :text

    add_foreign_key :conversations, :conversation_classifications, column: :classification_id
    add_index :conversations, :classification_id
  end
end
