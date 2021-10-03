class CreatePushKeys < ActiveRecord::Migration[6.1]
  def change
    create_table :push_keys do |t|
      t.string :provider, null: false
      t.string :public_key,  null: false, default: ''
      t.string :private_key, null: false, default: ''
      t.timestamps
    end
  end
end
