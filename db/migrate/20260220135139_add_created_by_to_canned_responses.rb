class AddCreatedByToCannedResponses < ActiveRecord::Migration[7.1]
  def change
    add_column :canned_responses, :created_by_id, :integer, null: true
    add_index :canned_responses, :created_by_id
  end
end
