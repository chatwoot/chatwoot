class AddVisibilityToCannedResponses < ActiveRecord::Migration[7.1]
  def change
    add_column :canned_responses, :visibility, :integer, default: 0, null: false

    add_index :canned_responses, :visibility
  end
end
