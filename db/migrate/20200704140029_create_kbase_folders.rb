class CreateKbaseFolders < ActiveRecord::Migration[6.0]
  def change
    create_table :kbase_folders do |t|
      t.integer :account_id
      t.string :name
      t.text :description
      t.integer :category_id

      t.timestamps
    end
  end
end
