class CreateEmailChannel < ActiveRecord::Migration[6.0]
  def change
    create_table :channel_email do |t|
      t.integer :account_id, null: false
      t.string :email, null: false, index: { unique: true }
      t.string :forward_to_address, null: false, index: { unique: true }
      t.timestamps
    end
  end
end
