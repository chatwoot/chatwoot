class CreateNotes < ActiveRecord::Migration[6.0]
  def change
    create_table :notes do |t|
      t.text :content, null: false
      t.references :account, foreign_key: true, null: false
      t.references :contact, foreign_key: true, null: false
      t.references :user, foreign_key: true
      t.timestamps
    end
  end
end
