class AddDropAssigneeOutsideTeamOnReopenToInboxes < ActiveRecord::Migration[7.1]
  def change
    add_column :inboxes, :drop_assignee_outside_team_on_reopen, :boolean, default: false, null: false
  end
end
