class AddEnableAutoAssignmentToInboxes < ActiveRecord::Migration[6.0]
  def change
    add_column :inboxes, :enable_auto_assignment, :boolean, default: true
  end
end
