class CreateQuickReplies < ActiveRecord::Migration[7.0]
  def change
    create_table :quick_replies do |t|
      t.string :name
      t.text :content
      t.references :account, null: false, foreign_key: true

      t.timestamps
    end
  end
end
