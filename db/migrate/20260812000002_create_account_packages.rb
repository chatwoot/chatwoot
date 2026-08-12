class CreateAccountPackages < ActiveRecord::Migration[7.1]
  def change
    create_table :account_packages do |t|
      t.bigint :account_id, null: false
      t.bigint :package_id, null: false
      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false

      t.timestamps
    end
    add_index :account_packages, :account_id
    add_index :account_packages, :package_id
    add_index :account_packages, [:account_id, :ends_at]
  end
end
