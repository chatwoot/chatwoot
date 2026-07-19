class AddCategoryToCannedResponses < ActiveRecord::Migration[7.1]
  def change
    add_column :canned_responses, :category, :string
    add_index :canned_responses, [:account_id, :category]
  end
end
