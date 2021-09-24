class AddAssigneeLastSeen < ActiveRecord::Migration[6.1]
  def change
    add_column :conversations, :assignee_last_seen_at, :datetime
  end
end
