class CreateSenderListEntries < ActiveRecord::Migration[7.1]
  def change
    create_table :sender_list_entries do |t|
      t.references :account, null: false, foreign_key: true
      t.integer :list_type, null: false
      t.string :value, null: false

      t.timestamps
    end

    add_index :sender_list_entries, [:account_id, :value], unique: true
  end
end
