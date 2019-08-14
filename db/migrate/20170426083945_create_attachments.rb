class CreateAttachments < ActiveRecord::Migration[5.0]
  def change
    create_table :attachments do |t|
      t.string :file
      t.integer :file_type, default: 0
      t.string :external_url
      t.integer :coordinates_lat, default: 0
      t.integer :coordinates_long, default: 0
      t.integer :message_id, null: false
      t.integer :account_id, null: false
      t.timestamps
    end
  end
end
