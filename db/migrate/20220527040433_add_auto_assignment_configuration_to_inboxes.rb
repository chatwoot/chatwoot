class AddAutoAssignmentConfigurationToInboxes < ActiveRecord::Migration[6.1]
  def change
    add_column :inboxes, :auto_assignment_config, :jsonb, default: {}
  end
end
