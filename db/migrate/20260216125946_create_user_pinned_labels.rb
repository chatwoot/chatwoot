class CreateUserPinnedLabels < ActiveRecord::Migration[7.1]
  def change
    create_table :user_pinned_labels do |t|
      t.references :user, null: false, foreign_key: true
      t.references :label, null: false, foreign_key: true
      t.integer :position, default: 0
      t.timestamps
    end

    add_index :user_pinned_labels, [:user_id, :label_id], unique: true
  end
end
