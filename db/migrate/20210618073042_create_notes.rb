class CreateNotes < ActiveRecord::Migration[6.0]
  def change
    create_table :notes do |t|
      t.string :content
      t.integer :author_id
      t.integer :account_id
      t.integer :contact_id
      t.timestamps
    end
  end
end
