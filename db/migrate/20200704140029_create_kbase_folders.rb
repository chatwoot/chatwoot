class CreateKbaseFolders < ActiveRecord::Migration[6.0]
  def change
    create_table :kbase_folders do |t|
      t.integer :account_id, null: false
      t.integer :category_id, null: false
      t.string :name

      t.timestamps
    end
  end
end
