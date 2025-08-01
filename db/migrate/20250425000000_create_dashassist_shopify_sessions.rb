class CreateDashassistShopifySessions < ActiveRecord::Migration[7.0]
  def change
    create_table :dashassist_shopify_sessions do |t|
      t.string :shop, null: false
      t.string :access_token, null: false
      t.datetime :expires_at, null: false
      t.string :scope, array: true, default: [], null: false
      
      t.timestamps
    end

    add_index :dashassist_shopify_sessions, :shop, unique: true
  end
end 