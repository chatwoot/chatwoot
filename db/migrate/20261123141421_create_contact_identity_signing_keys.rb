class CreateContactIdentitySigningKeys < ActiveRecord::Migration[8.0]
  def change
    create_table :contact_identity_signing_keys do |t|
      t.bigint :inbox_id, null: false
      t.string :secret, null: false

      t.timestamps
    end
    add_index :contact_identity_signing_keys, :inbox_id
  end
end
