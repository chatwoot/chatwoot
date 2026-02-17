class CreateKbFolders < ActiveRecord::Migration[7.0]
  def change
    create_table :kb_folders do |t|
      t.references :account, null: false, foreign_key: true
      t.string :name, null: false
      t.string :parent_path, null: false, default: '/'
      t.string :full_path, null: false
      t.references :created_by, foreign_key: { to_table: :users }, null: true
      t.timestamps
    end

    add_index :kb_folders, [:account_id, :full_path], unique: true
    add_index :kb_folders, [:account_id, :parent_path]
  end
end
