class CreateLibraryResources < ActiveRecord::Migration[7.1]
  def change
    create_table :library_resources do |t|
      t.integer :account_id, null: false
      t.string :title, null: false
      t.text :description, null: false
      t.text :content

      t.timestamps
    end

    add_index :library_resources, :account_id
    add_index :library_resources, :title
  end
end
