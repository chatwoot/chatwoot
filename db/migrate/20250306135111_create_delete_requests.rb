class CreateDeleteRequests < ActiveRecord::Migration[7.0]
  def change
    create_table :delete_requests do |t|
      t.string :fb_id, null: false
      t.string :status, null: false
      t.string :confirmation_code, null: false
      t.datetime :completed_at
      t.string :deleted_type
      t.integer :deleted_id
      t.references :account, index: true, null: true

      t.timestamps
    end

    add_index :delete_requests, :confirmation_code, unique: true
  end
end
