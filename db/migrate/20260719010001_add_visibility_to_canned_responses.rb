class AddVisibilityToCannedResponses < ActiveRecord::Migration[7.1]
  def up
    add_column :canned_responses, :visibility, :integer, default: 0, null: false
    add_reference :canned_responses, :created_by, foreign_key: { to_table: :users }, null: true

    # Existing responses were account-wide; keep them global for all agents.
    execute 'UPDATE canned_responses SET visibility = 1'
  end

  def down
    remove_reference :canned_responses, :created_by, foreign_key: { to_table: :users }
    remove_column :canned_responses, :visibility
  end
end
