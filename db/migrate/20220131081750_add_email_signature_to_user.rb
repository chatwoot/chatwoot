class AddEmailSignatureToUser < ActiveRecord::Migration[6.1]
  def change
    change_table :users, bulk: true do |t|
      t.boolean :message_signature_enabled, null: false, default: false
      t.text :message_signature, null: true
    end
  end
end
