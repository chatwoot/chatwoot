class CreateUserAuths < ActiveRecord::Migration[7.0]
  def change
    create_table :user_auths do |t|
      t.references :user, null: false, foreign_key: true, index: true
      t.string :tenant_id, null: false
      t.text :access_token, null: false
      t.string :client_id, null: false
      t.string :client_secret, null: false
      t.text :refresh_token, null: false
      t.datetime :expiration_datetime, null: false

      t.timestamps
    end
  end
end
