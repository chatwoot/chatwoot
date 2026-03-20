class CreateInboxSignatures < ActiveRecord::Migration[7.1]
  def change
    create_table :inbox_signatures do |t|
      t.references :user, null: false, index: false
      t.references :inbox, null: false, index: false
      t.text :message_signature, null: false
      t.string :signature_position, default: 'top', null: false
      t.string :signature_separator, default: 'blank', null: false
      t.timestamps
    end

    add_index :inbox_signatures, %i[user_id inbox_id], unique: true
  end
end
