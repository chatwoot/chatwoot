class AddPreventAssignmentTakeoverToInboxes < ActiveRecord::Migration[7.1]
  def change
    add_column :inboxes, :prevent_assignment_takeover, :boolean, default: false, null: false
  end
end
