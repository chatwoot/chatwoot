class CreateCustomFilters < ActiveRecord::Migration[6.0]
  def change
    create_table :custom_filters do |t|
      t.string :name, null: false
      t.integer :filter_type, null: false, default: 0
      t.jsonb :query, null: false, default: '{}'
      t.references :account, index: true, null: false
      t.references :user, index: true, null: false
      t.timestamps
    end
  end
end
