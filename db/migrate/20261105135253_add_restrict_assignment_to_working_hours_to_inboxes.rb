class AddRestrictAssignmentToWorkingHoursToInboxes < ActiveRecord::Migration[7.2]
  def change
    add_column :inboxes, :restrict_assignment_to_working_hours, :boolean, default: false, null: false
  end
end
