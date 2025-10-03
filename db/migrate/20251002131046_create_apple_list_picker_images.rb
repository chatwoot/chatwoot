class CreateAppleListPickerImages < ActiveRecord::Migration[7.1]
  def change
    create_table :apple_list_picker_images do |t|
      t.references :account, null: false, foreign_key: true
      t.references :inbox, null: false, foreign_key: true
      t.string :identifier, null: false
      t.string :description
      t.string :original_name

      t.timestamps
    end

    add_index :apple_list_picker_images, [:inbox_id, :identifier], unique: true
  end
end
