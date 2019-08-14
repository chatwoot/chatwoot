class CreateFacebookPages < ActiveRecord::Migration[5.0]
  def change
    create_table :facebook_pages do |t|
      t.string :name
      t.string :page_id, null: false
      t.string :user_access_token, null: false
      t.string :page_access_token, null: false
      t.integer :account_id, null: false
      t.integer :inbox_id, null: false
      t.timestamps
    end
  end
end
