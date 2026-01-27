class CreateReusableAttachments < ActiveRecord::Migration[7.0]
  def change
    create_table :reusable_attachments do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.string :name, null: false
      t.integer :file_type, default: 0, null: false
      t.string :extension
      t.text :description

      t.timestamps
    end

    add_index :reusable_attachments, [:account_id, :name]
  end
end
