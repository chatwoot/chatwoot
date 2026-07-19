class AddApprovalStatusToCannedResponses < ActiveRecord::Migration[7.1]
  def up
    add_column :canned_responses, :approval_status, :integer, default: 0, null: false
    add_reference :canned_responses, :reviewed_by, foreign_key: { to_table: :users }, null: true
    add_column :canned_responses, :reviewed_at, :datetime

    # Existing responses were already usable; keep them approved.
    execute 'UPDATE canned_responses SET approval_status = 1'
  end

  def down
    remove_column :canned_responses, :reviewed_at
    remove_reference :canned_responses, :reviewed_by, foreign_key: { to_table: :users }
    remove_column :canned_responses, :approval_status
  end
end
