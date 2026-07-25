class AddCategoryToFlows < ActiveRecord::Migration[7.1]
  def change
    add_column :flows, :category, :string
    add_index :flows, [:account_id, :category]
  end
end
